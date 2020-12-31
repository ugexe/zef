use Zef;
use Zef::Utils::FileSystem;

class Zef::Service::Shell::Test does Tester does Messenger {

    =begin pod

    =title class Zef::Service::Shell::Test

    =subtitle A raku executable based implementation of the Tester interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::Test;

        my $test = Zef::Service::Shell::Test.new;

        # Add logging if we want to see output
        $test.stdout.Supply.tap: { say $_ };
        $test.stderr.Supply.tap: { note $_ };

        # Assuming our current directory is a raku distribution
        # with no dependencies or all dependencies already installed...
        my $dist-to-test = $*CWD;
        my Str @includes = $*CWD.absolute;
        my $passed = so $test.test($dist-to-test, :@includes);
        say $passed ?? "PASS" !! "FAIL";

    =end code

    =head1 Description

    C<Tester> class for handling path based URIs ending in .rakutest / .t6 / .t using the C<raku> command.

    You probably never want to use this unless its indirectly through C<Zef::Test>;
    handling files and spawning processes will generally be easier using core language functionality. This
    class exists to provide the means for fetching a file using the C<Tester> interfaces that the e.g. Test/TAP
    adapters use.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully launch the C<raku> command (i.e. always returns C<True>).

    =head2 method test-matcher

        method test-matcher(Str() $path --> Bool:D)

    Returns C<True> if this module knows how to test C<$uri>. This module always returns C<True> right now since
    it just launches tests directly with the C<raku> command.

    =head2 method test

        method test(IO() $path, Str :@includes --> Bool:D)

    Test the files ending in C<.rakutest> C<.t6> or C<.t> in the C<t/> directory of the given C<$path> using the
    provided C<@includes> (e.g. C</foo/bar> or C<inst#/foo/bar>) via the C<prove> command.

    Returns C<True> if all test files exited with 0.

    =end pod


    #| Returns true always since it just uses $*EXECUTABLE
    method probe(--> Bool:D) { True }

    #| Return true if this Tester understands the given uri/path
    method test-matcher(Str() $path --> Bool:D) { return True }

    #| Test the given paths t/ directory using any provided @includes
    method test(IO() $path, :@includes --> Bool:D) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my $test-path = $path.child('t');
        return True unless $test-path.e;

        my @rel-test-files = sort
            map *.IO.relative($path),
            grep *.extension eq any('rakutest', 't', 't6'),
            list-paths($test-path.absolute, :f, :!d, :r);
        return True unless +@rel-test-files;

        my @results = @rel-test-files.map: -> $rel-test-file {
            my %ENV = %*ENV;
            my @cur-lib  = %ENV<RAKULIB>.?chars ?? %ENV<RAKULIB>.split($*DISTRO.cur-sep) !! ();
            my @new-lib  = $path.absolute, |@includes;
            %ENV<RAKULIB> = (|@new-lib, |@cur-lib).join($*DISTRO.cur-sep);

            my $passed;
            react {
                my $proc = Zef::zrun-async($*EXECUTABLE.absolute, $rel-test-file);
                whenever $proc.stdout.lines { $.stdout.emit($_) }
                whenever $proc.stderr.lines { $.stderr.emit($_) }
                whenever $proc.start(:%ENV, :cwd($path)) { $passed = $_.so }
            }
            $passed;
        }

        return so @results.all;
    }
}
