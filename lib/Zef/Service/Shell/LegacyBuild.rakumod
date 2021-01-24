use Zef;
use Zef::Distribution::Local;

class Zef::Service::Shell::LegacyBuild does Builder does Messenger {

    =begin pod

    =title class Zef::Service::Shell::LegacyBuild

    =subtitle A raku based implementation of the Builder interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::LegacyBuild;

        my $builder = Zef::Service::Shell::LegacyBuild.new;

        # Add logging if we want to see output
        $builder.stdout.Supply.tap: { say $_ };
        $builder.stderr.Supply.tap: { note $_ };

        # Assuming our current directory is a raku distribution with a
        # Build.rakumod and has no dependencies (or all dependencies
        # already installed)...
        my $dist-to-build = Zef::Distribution::Local.new($*CWD);
        my Str @includes = $*CWD.absolute;
        my $built-ok = so $builder.build($dist-to-build, :@includes);
        say $built-ok ?? "OK" !! "Something went wrong";

    =end code

    =head1 Description

    C<Builder> class for handling local distributions that include a .rakumod / .pm6 / .pm alongside their C<META6.json>.
    Launches an e.g. 'Build.rakumod' file of the provided distribution with the raku executable.

    Note: These type of build files will be deprecated one day in the (possibly far) future. Prefer build tools like
    C<Distribution::Builder::MakeFromJSON> (which uses C<Zef::Service::Shell::DistributionBuilder>) if possible.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully launch the C<raku> command (i.e. always returns C<True>).

    =head2 method build-matcher

        method build-matcher(Zef::Distribution::Local $dist --> Bool:D)

    Returns C<True> if this module knows how to test C<$uri>, which it decides based on if the files extracted from
    C<$dist> contains any of C<Build.rakumod> C<Build.pm6> or C<Build.pm> (must be extracted as these do not get declared
    in a META6.json file).

    =head2 method build

        method build(Zef::Distribution::Local $dist, Str :@includes --> Bool:D)

    Launch the e.g. C<Build.rakumod> module in the root directory of an extracted C<$dist> using the provided C<@includes>
    (e.g. C</foo/bar> or C<inst#/foo/bar>) via the C<raku> command (essentially doing C<::(Build).new.build($dist-dir)>).

    Returns C<True> if the C<raku> process spawned to run the build module exits 0.

    =end pod


    #| Get the path of the Build file that will be executed
    method !guess-build-file(IO() $prefix --> IO::Path) { return <Build.rakumod Build.pm6 Build.pm>.map({ $prefix.child($_) }).first({ $_.e }) }

    #| Return true always since it just requires launching another raku process
    method probe(--> Bool:D) { True }

    #| Return true if this Builder understands the given uri/path of the provided distribution
    method build-matcher(Zef::Distribution::Local $dist --> Bool:D) { return so self!guess-build-file($dist.path) }

    #| Run the Build.rakumod of the given distribution
    method build(Zef::Distribution::Local $dist, Str :@includes --> Bool:D) {
        die "path does not exist: {$dist.path}" unless $dist.path.IO.e;

        my $build-file = self!guess-build-file($dist.path).absolute;
        my $cmd        = "require '$build-file'; ::('Build').new.build('$dist.path.IO.absolute()') ?? exit(0) !! exit(1);";
        my @exec       = |($*EXECUTABLE.absolute, |@includes.grep(*.defined).map({ "-I{$_}" }), '-e', "$cmd");

        $.stdout.emit("Command: {@exec.join(' ')}");

        my $ENV := %*ENV;
        my $passed;
        react {
            my $proc = Zef::zrun-async(@exec);
            whenever $proc.stdout.lines { $.stdout.emit($_) }
            whenever $proc.stderr.lines { $.stderr.emit($_) }
            whenever $proc.start(:$ENV, :cwd($dist.path)) { $passed = $_.so }
        }
        return $passed;
    }
}
