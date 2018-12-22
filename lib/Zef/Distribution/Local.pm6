use Zef;
use Zef::Distribution;

class Zef::Distribution::Local is Zef::Distribution {
    has $.path;
    has $.IO;

    # if $path = dir/meta6.json, $.path is set to dir
    # if $path = dir/, $.path is set to the first meta file (if any) thats found
    method new($path) {
        die "Cannot create a Zef::Distribution from non-existent path: {$path}" unless $path.IO.e;
        my $meta-path = self.find-meta($path)                  || die "No meta file? Path: {$path}";
        my $abspath   = $meta-path.parent.absolute;
        my %meta      = try { %(from-json($meta-path.slurp)) } || die "Invalid json? File: {$meta-path}";
        my $IO        = $abspath.IO;
        self.bless(:path($abspath), :$IO, |%(%meta.grep(?*.value.elems)), :meta(%meta));
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

    method resources(Bool :$absolute) {
        my $res-path = self.IO.child('resources');

        # resources/libraries is treated differently than everything else.
        # It uses the internal platform-library-name method to apply an
        # automatic platform naming scheme to the paths. It maps the original
        # path to this new path so that CURI.install can understand it.
        # Example:
        #   META FILE: 'resources/libraries/mylib'
        #   GENERATED: 'resources/libraries/mylib' => 'resources/libaries/libmylib.so'
        #           or 'resources/libraries/mylib' => 'resources/libaries/mylib.dll'
        # Note that it does not add the "lib" prefix on Windows. Whether the generated file has the "lib" prefix is platform dependent. 
        my $lib-path = $res-path.child('libraries');

        % = self.hash<resources>.map: -> $resource {
            my $resource-path = $resource ~~ m/^libraries\/(.*)/
                ?? $lib-path.child($*VM.platform-library-name(IO::Path.new($0, :CWD($!path))))
                !! $res-path.child($resource);
            $resource => $resource-path.IO.is-relative
                ?? ( ?$absolute ?? $resource-path.IO.absolute($!path) !! $resource-path )
                !! ( !$absolute ?? $resource-path.IO.relative($!path) !! $resource-path );
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

    method scripts(Bool :$absolute) {
        % = do with $.IO.child('bin') -> $bin {
            # Get all files in bin/ directory and map them into
            # a hash CURI.install understands: "zef" => "bin/zef"
            $bin.dir.grep(*.IO.f).map({
                $_.IO.basename => $_.IO.is-relative
                    ?? ( ?$absolute ?? $_.IO.absolute($!path) !! $_ )
                    !! ( !$absolute ?? $_.IO.relative($!path) !! $_ )
            }).hash if $bin.IO.d
        }
    }

    method meta {
        my %hash = self.hash;
        self.resources.map: { %hash<files>{"resources/" ~ .key} = .value }
        self.scripts.map:   { %hash<files>{"bin/" ~ .key}       = .value }
        %hash;
    }

    method content($address) {
        my $handle = IO::Handle.new: path => IO::Path.new($address, :CWD(self.IO));
        $handle // $handle.throw;
    }
}
