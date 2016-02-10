use Zef::Distribution;

class Zef::Distribution::Local is Zef::Distribution {
    has $.path;
    has $.IO;

    # if $path = dir/meta6.json, $.path is set to dir
    # if $path = dir/, $.path is set to the first meta file (if any) thats found
    method new($path) {
        die "Cannot create a Zef::Distribution from non-existant path: {$path}" unless $path.IO.e;
        my $meta-path = self.find-meta($path)                  || die "No meta file? Path: {$path}";
        my $abspath   = $meta-path.parent.absolute;
        my %meta      = try { %(from-json($meta-path.slurp)) } || die "Invalid json? File: {$meta-path} Error: $_";
        my $IO        = IO::Path.new-from-absolute-path($abspath);
        self.bless(:path($abspath), :$IO, |%(%meta.grep(?*.value.elems)));
    }

    method find-meta(Zef::Distribution::Local: $path? is copy) {
        my $dir = $path ~~ IO::Path
            ?? $path
            !! $path.?chars
                ?? $path.IO
                !! self.IO;
        return $dir if !$dir || $dir.IO.f;

        # META.info and META6.info are not spec, but are still in use.
        # The windows path size check is for windows symlink wonkiness.
        # "12" is the minimum size required for a valid meta that
        # rakudos internal json parser can understand (and is longer than
        # what the symlink issue noted above usually involves)
        my $meta-variants = <META6.json META.info META6.info>.map: { $ = $dir.child($_) }
        my $chosen-meta   = $meta-variants.grep(*.IO.e).first: -> $file {
            so ($file.e && ($*DISTRO.is-win ?? ((try $file.s) > 12) !! $file.f));
        } || IO::Path;
    }

    method resources {
        my $res-path = self.IO.child('resources');
        my $lib-path = $res-path.child('libraries');

        % = self.hash<resources>.map: -> $resource {
            $resource => $resource ~~ m/^libraries\/(.*)/
                ?? $lib-path.child($*VM.platform-library-name(IO::Path.new($0, :CWD($!path))))
                !! $res-path.child($resource);
        }
    }

    method sources(Bool :$absolute) {
        % = self.hash<provides>.grep(*.so).map: {
            .key => .value.IO.is-relative
                ?? ( ?$absolute ?? .value.IO.absolute($!path) !! .value )
                !! ( !$absolute ?? .value.IO.relative($!path) !! .value );
        }
    }

    method scripts {
        % = do with $.IO.child('bin') -> $bin { $bin.dir.grep(*.IO.f).map({ .IO.basename => $_ }).hash if $bin.IO.d };
    }
}
