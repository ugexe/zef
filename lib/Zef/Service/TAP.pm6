use Zef;
use Zef::Utils::FileSystem;

class Zef::Service::TAP does Tester does Messenger {
    # Return true if this Tester understands the given uri/path
    method test-matcher($path --> Bool:D) { return True }

    # Return true if the `TAP::Harness` raku module is available
    method probe(--> Bool:D) { state $probe = (try require TAP::Harness) !~~ Nil ?? True !! False }

    # Test the given paths t/ directory using any provided @includes
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
        my $out;
        my $err;
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
