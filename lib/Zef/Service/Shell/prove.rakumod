use Zef;

class Zef::Service::Shell::prove does Tester {

    =begin pod

    =title class Zef::Service::Shell::prove

    =subtitle A prove based implementation of the Tester interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::prove;

        my $prove = Zef::Service::Shell::prove.new;

        # Add logging if we want to see output
        my $stdout = Supplier.new;
        my $stderr = Supplier.new;
        $stdout.Supply.tap: { say $_ };
        $stderr.Supply.tap: { note $_ };

        # Assuming our current directory is a raku distribution
        # with no dependencies or all dependencies already installed...
        my $dist-to-test = $*CWD;
        my Str @includes = $*CWD.absolute;
        my $passed = so $prove.test($dist-to-test, :@includes, :$stdout, :$stderr);
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

        method test(IO() $path, Str :@includes, Supplier :$stdout, Supplier :$stderr --> Bool:D)

    Test the files ending in C<.rakutest> C<.t6> or C<.t> in the C<t/> directory of the given C<$path> using the
    provided C<@includes> (e.g. C</foo/bar> or C<inst#/foo/bar>) via the C<prove> command. A C<Supplier> can be
    supplied as C<:$stdout> and C<:$stderr> to receive any output.

    Returns C<True> if all tests passed according to C<prove>.

    =end pod

    my Lock $probe-lock = Lock.new;
    my Bool $probe-cache;

    #| Return true if the `prove` command is available to use
    method probe(--> Bool:D) {
        $probe-lock.protect: {
            return $probe-cache if $probe-cache.defined;
            my $probe = self!probe;
            return $probe-cache = $probe;
        }
    }

    method !probe(--> Bool:D) {
        if $*EXECUTABLE.absolute.contains(" ") {
            # prove can't deal with spaces in the executable path.
            # It assumes everything after the first space to be args to the
            # executable. So we can't use prove if our executables path
            # contains a space. Sad.
            # https://metacpan.org/dist/Test-Harness/view/bin/prove#-exec
            return False
        }
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
                    return True if $proc.exitcode == 1 && @out.first(*.contains("-exec" | "Mac OS"));
                }
                default { return False }
            }
        }
        # Should't reach here based on prior exitcode comment
        return False;
    }

    #| Return true if this Tester understands the given uri/path
    method test-matcher(Str() $uri --> Bool:D) { return $uri.IO.e }

    #| Test the given paths t/ directory using any provided @includes
    method test(IO() $path, Str :@includes, Supplier :$stdout, Supplier :$stderr --> Bool:D) {
        die "cannot test path that does not exist: {$path}" unless $path.e;
        my $test-path = $path.child('t');
        return True unless $test-path.e;

        my Str $test-path-relative = $test-path.relative($path);
        my Str $test-path-cwd      = $path.absolute;

        my %ENV = %*ENV;
        my @cur-lib  = %ENV<RAKULIB>.?chars ?? %ENV<RAKULIB>.split($*DISTRO.cur-sep) !! ();
        my @new-lib  = $path.absolute, |@includes;
        %ENV<RAKULIB> = (|@new-lib, |@cur-lib).join($*DISTRO.cur-sep);

        my @args =
            '--ext', '.rakutest',
            '--ext', '.t',
            '--ext', '.t6',
            '-r',
            ('--verbose' if %*ENV<HARNESS_VERBOSE>),
        ;
        my $passed;
        react {
            my $proc = $*DISTRO.is-win
                ?? Proc::Async.new(:win-verbatim-args, 'prove.bat', |@args, '-e',
                    '"' ~ $*EXECUTABLE.absolute ~ '"',
                    '"' ~ $test-path-relative ~ '"')
                !! Proc::Async.new('prove', |@args, '-e',
                    $*EXECUTABLE.absolute,
                    $test-path-relative);
            whenever $proc.stdout.lines { $stdout.emit($_) }
            whenever $proc.stderr.lines { $stderr.emit($_) }
            whenever $proc.start(:%ENV, :cwd($test-path-cwd)) { $passed = $_.so }
        }
        return so $passed;
    }
}
