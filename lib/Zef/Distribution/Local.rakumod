use Zef:ver($?DISTRIBUTION.meta<version> // $?DISTRIBUTION.meta<ver>// '*'):api($?DISTRIBUTION.meta<api> // '*'):auth($?DISTRIBUTION.meta<auth> // '');
use Zef::Distribution:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);

class Zef::Distribution::Local is Zef::Distribution {

    =begin pod

    =title class Zef::Distribution::Local

    =subtitle A local file system Distribution implementation

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef::Distribution::Local;

        my $dist = Zef::Distribution::Local.new($*CWD);

        # Show the meta data
        say $dist.meta.raku;

        # Output the content of the first item in provides
        with $dist.meta<provides>.hash.values.head -> $name-path {
            say $dist.content($name-path).open.slurp;
        }

        # Output if the $dist contains a namespace matching Foo::Bar:ver<1>
        say $dist.contains-spec("Foo::Bar:ver<1>");

    =end code

    =head1 Description

    A C<Distribution> implementation that is used to represent locally downloaded and extracted distributions.

    =head1 Methods

    =head2 method new

        method new(IO() $path)

    Create a C<Zef::Distribution::Local> from a local distribution via its C<META6.json> file.
    If C<$path> is a directory then it will assume there is a C<META6.json> file it can use.
    If C<$path> is a file it will assume it a json file containing meta data (formatted like C<META6.json>).

    =head2 method meta

        method meta(--> Hash:D)

    Returns the meta data that represents the distribution.

    =head2 method content

        method content($name-path --> IO::Handle:D)

    Returns an unopened C<IO::Handle> that can be used to get the content of the C<$name-path>, where C<$name-path>
    is a value of the distributions C<provides> e.g. C<lib/Foo.rakumod>, C<$dist.content($dist.meta<provides>{"Foo"})>.

    =end pod


    has $.path;
    has $.IO;

    #| Create a distribution from $path.
    #| If $path = dir/meta6.json, $.path is set to dir.
    #| If $path = dir/, $.path is set to the first meta file (if any) thats found.
    method new(IO() $path) {
        die "Cannot create a Zef::Distribution from non-existent path: {$path}" unless $path.e;
        my $meta-path = self!find-meta($path)                  || die "No meta file? Path: {$path}";
        my $abspath   = $meta-path.parent.absolute;
        my %meta      = try { %(Zef::from-json($meta-path.slurp)) } || die "Invalid json? File: {$meta-path}";
        my $IO        = $abspath.IO;
        self.bless(:path($abspath), :$IO, |%(%meta.grep(?*.value.elems)), :meta(%meta));
    }

    has %!meta-cache;
    #| Get the meta data this distribution provides
    method meta(--> Hash:D) {
        return %!meta-cache if %!meta-cache;
        my %hash = self.Zef::Distribution::meta;
        # These are required for installation, but not part of META6 spec
        # Eventually there needs to be a spec for authors to declare their bin scripts,
        # and CUR should probably handle the resources file mapping itself (since all
        # data needed to calculate it exists under the 'resources' field).
        %hash<files>{"resources/" ~ .key} = .value for self!resources(:meta(%hash)).list;
        %hash<files>{"bin/" ~ .key}       = .value for self!scripts.list;
        return %!meta-cache := %hash;
    }

    #| Get a handle used to read/slurp data from files this distribution contains
    method content($name-path --> IO::Handle:D) {
        my $handle = IO::Handle.new: path => IO::Path.new($name-path, :CWD(self.IO));
        return $handle // $handle.throw;
    }

    #| Given a path that might be a file or directory it makes a best guess at what the implied META6.json is.
    method !find-meta(Zef::Distribution::Local: $path? is copy --> IO::Path) {
        my $dir = $path ~~ IO::Path # Purpose: Turn whatever the user gives us to a IO::Path if possible
            ?? $path                # - Already IO::Path
            !! $path.?chars         # - If $path is Any it won't have .chars (hence .?chars)
                ?? $path.IO         # - A string with at least 1 char is needed to call `.IO`
                !! self.IO;         # - Assume its meant to be called on itself (todo: check $path.defined)

        # If a file was passed in then we assume its a metafile. Normally you'd pass
        # in a directory containing the meta file, but for convience we'll do this for files
        return $dir if !$dir || $dir.IO.f;

        # The windows path size check is for windows symlink wonkiness.
        # "12" is the minimum size required for a valid meta that
        # rakudos internal json parser can understand (and is longer than
        # what the symlink issue noted above usually involves)
        my $meta-file = $dir.add('META6.json');
        return $meta-file.IO.e ?? $meta-file !! IO::Path;
    }

    #| Get all files in resources/ directory and map them into a hash CURI.install understands.
    method !resources(:%meta, Bool :$absolute --> Hash:D) {
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

        return %meta<resources>.grep(*.defined).map(-> $resource {
            my $resource-path = $resource ~~ m/^libraries\/(.*)/
                ?? $lib-path.child($*VM.platform-library-name(IO::Path.new($0, :CWD($!path))))
                !! $res-path.child($resource);
            $resource => $resource-path.IO.is-relative
                ?? ( ?$absolute ?? $resource-path.IO.absolute($!path) !! $resource-path )
                !! ( !$absolute ?? $resource-path.IO.relative($!path) !! $resource-path );
        }).hash;
    }

    #| Get all files in bin/ directory and map them into a hash CURI.install understands.
    method !scripts(Bool :$absolute --> Hash:D) {
        do with $.IO.child('bin') -> $bin {
            return $bin.dir.grep(*.IO.f).map({
                $_.IO.basename => $_.IO.is-relative
                    ?? ( ?$absolute ?? $_.IO.absolute($!path) !! $_ )
                    !! ( !$absolute ?? $_.IO.relative($!path) !! $_ )
            }).hash if $bin.IO.d
        }
        return {};
    }
}
