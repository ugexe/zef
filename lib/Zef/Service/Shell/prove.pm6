use Zef;

class Zef::Service::Shell::prove does Tester does Messenger {

    =begin pod

    =title class Zef::Service::Shell::prove

    =subtitle A prove based implementation of the Tester interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::prove;

        my $prove = Zef::Service::Shell::prove.new;

        # Add logging if we want to see output
        $prove.stdout.Supply.tap: { say $_ };
        $prove.stderr.Supply.tap: { note $_ };

        # Assuming our current directory is a raku distribution
        # with no dependencies or all dependencies already installed...
        my $dist-to-test = $*CWD;
        my Str @includes = $*CWD.absolute;
        my $passed = so $prove.test($dist-to-test, :@includes);
        say $passed ?? "PASS" !! "FAIL";

    =end code

    =head1 Description

    C<Tester> class for handling path based URIs ending in .rakutest / .t6 / .t using the C<prove> command.

    You probably never want to use this unless its indirectly through C<Zef::Test>;
    handling files and spawning processes will generally be easier using core language functionality. This
    class exists to provide the means for fetching a file using the C<Tester> interfaces that the e.g. Test/TAP
    adapters use.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully launch the C<prove> command.

    =head2 method test-matcher

        method test-matcher(Str() $uri --> Bool:D)

    Returns C<True> if this module knows how to test C<$uri>, which it decides based on if C<$uri> exists
    on local file system.

    =head2 method test

        method test(IO() $path, Str :@includes --> Bool:D)

    Test the files ending in C<.rakutest> C<.t6> or C<.t> in the C<t/> directory of the given C<$path> using the
    provided C<@includes> (e.g. C</foo/bar> or C<inst#/foo/bar>) via the C<prove> command.

    Returns C<True> if all tests passed according to C<prove>.

    =end pod


    #| Return true if the `prove` command is available to use
    method probe(--> Bool:D) {
        state $probe;
        once {
            # `prove --help` has exitcode == 1 unlike most other processes
            # so it requires a more convoluted probe check
            try {
                my $proc = $*DISTRO.is-win
                    ?? Zef::zrun('prove.bat', '--help', :out, :!err)
                    !! Zef::zrun('prove', '--help', :out, :!err);
                my @out  = $proc.out.lines;
                $proc.out.close;
                CATCH {
                    when X::Proc::Unsuccessful {
                        $probe = True if $proc.exitcode == 1 && @out.first(*.contains("-exec" | "Mac OS X"));
                    }
                    default { return False }
                }
            }
        }
        ?$probe;
    }

    #| Return true if this Tester understands the given uri/path
    method test-matcher(Str() $uri --> Bool:D) { return $uri.IO.e }

    #| Test the given paths t/ directory using any provided @includes
    method test(IO() $path, Str :@includes --> Bool:D) {
        die "cannot test path that does not exist: {$path}" unless $path.e;
        my $test-path = $path.child('t');
        return True unless $test-path.e;

        my Str $test-path-relative = $test-path.relative($path);
        my Str $test-path-cwd      = $path.absolute;

        my %ENV = %*ENV;
        my @cur-p6lib  = %ENV<PERL6LIB>.?chars ?? %ENV<PERL6LIB>.split($*DISTRO.cur-sep) !! ();
        my @new-p6lib  = $path.absolute, |@includes;
        %ENV<PERL6LIB> = (|@new-p6lib, |@cur-p6lib).join($*DISTRO.cur-sep);

        my $passed;
        react {
            my $proc = $*DISTRO.is-win
                ?? Proc::Async.new(:win-verbatim-args, 'prove.bat', '--ext',
                    '.rakutest', '--ext', '.t', '--ext', '.t6', '-r', '-e',
                    '"' ~ $*EXECUTABLE.absolute ~ '"',
                    '"' ~ $test-path-relative ~ '"')
                !! Proc::Async.new('prove', '--ext', '.rakutest', '--ext',
                    '.t', '--ext', '.t6', '-r', '-e', $*EXECUTABLE.absolute,
                    $test-path-relative);
            whenever $proc.stdout.lines { $.stdout.emit($_) }
            whenever $proc.stderr.lines { $.stderr.emit($_) }
            whenever $proc.start(:%ENV, :cwd($test-path-cwd)) { $passed = $_.so }
        }
        return so $passed;
    }
}
