use Zef;
use Zef::Utils::FileSystem;

class Zef::Service::TAP does Tester does Messenger {

    =begin pod

    =title class Zef::Service::TAP

    =subtitle A TAP module based implementation of the Tester interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::TAP;

        my $tap = Zef::Service::TAP.new;

        # Add logging if we want to see output
        $tap.stdout.Supply.tap: { say $_ };
        $tap.stderr.Supply.tap: { note $_ };

        # Assuming our current directory is a raku distribution
        # with no dependencies or all dependencies already installed...
        my $dist-to-test = $*CWD;
        my Str @includes = $*CWD.absolute;
        my $passed = so $tap.test($dist-to-test, :@includes);
        say $passed ?? "PASS" !! "FAIL";

    =end code

    =head1 Description

    C<Tester> class for handling path based URIs ending in .rakutest / .t6 / .t using the raku C<TAP> module.

    You probably never want to use this unless its indirectly through C<Zef::Test>;
    handling files and spawning processes will generally be easier using core language functionality. This
    class exists to provide the means for fetching a file using the C<Tester> interfaces that the e.g. Test/prove
    adapters use.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully load the C<TAP::Harness> module.

    =head2 method test-matcher

        method test-matcher(Str() $uri --> Bool:D)

    Returns C<True> if this module knows how to test C<$uri>, which it decides based on if C<$uri> exists
    on local file system.

    =head2 method test

        method test(IO() $path, Str :@includes --> Bool:D)

    Test the files ending in C<.rakutest> C<.t6> or C<.t> in the C<t/> directory of the given C<$path> using the
    provided C<@includes> (e.g. C</foo/bar> or C<inst#/foo/bar>) via the C<TAP::Harness> raku module.

    Returns C<True> if there were no failed tests and no errors according to C<TAP::Harness>.

    =end pod


    #| Return true if the `TAP::Harness` raku module is available
    method probe(--> Bool:D) { state $probe = (try require TAP::Harness) !~~ Nil ?? True !! False }

    #| Return true if this Tester understands the given uri/path
    method test-matcher(Str() $uri --> Bool:D) { return $uri.IO.e }

    #| Test the given paths t/ directory using any provided @includes
    method test(IO() $path, Str :@includes --> Bool:D) {
        die "path does not exist: {$path}" unless $path.e;

        my $test-path = $path.child('t');
        return True unless $test-path.e;
        my @test-files = grep *.extension eq any('rakutest', 't', 't6'),
            list-paths($test-path.absolute, :f, :!d, :r).sort;
        return True unless +@test-files;

        # Much of the code below is to capture what TAP::Harness prints to stdout / stderr so that
        # we can instead emit that output as events (or just not output anything at all depending
        # on the verbosity level). There might be a better way to do all of this now; this code is old.
        my $stdout = $*OUT;
        my $stderr = $*ERR;
        my $out-supply = $.stdout;
        my $err-supply = $.stderr;
        my $cwd = $*CWD;

        my class OUT_CAPTURE is IO::Handle {
            method print(*@_) {
                temp $*OUT = $stdout;
                $out-supply.emit(.chomp) for @_;
                True;
            }
            method flush {}
        }

        my class ERR_CAPTURE is IO::Handle {
            method print(*@_) {
                temp $*ERR = $stderr;
                $err-supply.emit(.chomp) for @_;
                True;
            }
            method flush {}
        }

        my $result = try {
            require TAP;
            chdir($path);
            $*OUT = OUT_CAPTURE.new;
            $*ERR = ERR_CAPTURE.new;
            my @incdirs  = $path.absolute, |@includes;
            my @handlers = ::("TAP::Harness::SourceHandler::Perl6").new(:@incdirs);
            my $parser   = ::("TAP::Harness").new(:@handlers);
            my $promise  = $parser.run(@test-files>>.relative($path));
            my $result = $promise.result;
            $result;
        }
        chdir($cwd);

        $out-supply.done;
        $err-supply.done;
        $*OUT = $stdout;
        $*ERR = $stderr;

        my $passed = $result.failed == 0 && not $result.errors ?? True !! False;
        return $passed;
    }
}
