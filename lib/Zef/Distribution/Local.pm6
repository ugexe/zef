use Zef;
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
        my $dir = $path ~~ IO::Path # Purpose: Turn whatever the user gives us to a IO::Path if possible
            ?? $path                # - Already IO::Path
            !! $path.?chars         # - If $path is Any it won't have .chars (hence .?chars)
                ?? $path.IO         # - A string with at least 1 char is needed to call `.IO`
                !! self.IO;         # - Assume its meant to be called on itself (todo: check $path.defined)

        # If a file was passed in then we assume its a metafile. Normally you'd pass
        # in a directory containing the meta file, but for convience we'll do this for files
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

        # resources/libraries is treated differently than everything else.
        # It uses the internal platform-library-name method to apply an
        # automatic platform naming scheme to the paths. It maps the original
        # path to this new path so that CURI.install can understand it.
        # Example:
        #   META FILE: 'resources/libraries/mylib'
        #   GENERATED: 'resources/libraries/mylib' => 'resources/libaries/mylib.so'
        #           or 'resources/libraries/mylib' => 'resources/libaries/mylib.dll'
        my $lib-path = $res-path.child('libraries');

        % = self.hash<resources>.map: -> $resource {
            $resource => $resource ~~ m/^libraries\/(.*)/
                ?? $lib-path.child($*VM.platform-library-name(IO::Path.new($0, :CWD($!path))))
                !! $res-path.child($resource);
        }
    }

    method sources(Bool :$absolute) {
        # Re-map the module name to file path, possibly absolutifying the path
        % = self.hash<provides>.grep(*.so).map: {
            .key => .value.IO.is-relative
                ?? ( ?$absolute ?? .value.IO.absolute($!path) !! .value )
                !! ( !$absolute ?? .value.IO.relative($!path) !! .value );
        }
    }

    method scripts {
        % = do with $.IO.child('bin') -> $bin {
            # Get all files in bin/ directory and map them into
            # a hash CURI.install understands: "zef" => "bin/zef"
            $bin.dir.grep(*.IO.f).map({ .IO.basename => $_ }).hash if $bin.IO.d
        }
    }
}
