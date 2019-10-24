use Zef;
use Zef::Utils::FileSystem;

class Zef::Service::TAP does Tester does Messenger {
    method test-matcher($path) { True }

    method probe { state $probe = (try require TAP::Harness) !~~ Nil ?? True !! False }

    method test($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;

        my $test-path = $path.IO.child('t');
        return True unless $test-path.e;
        my @test-files = grep *.extension eq any('rakutest', 't', 't6'),
            list-paths($test-path.absolute, :f, :!d, :r).sort;
        return True unless +@test-files;

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
            my @incdirs  = $path.IO.absolute, |@includes;
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

        $result.failed == 0 && not $result.errors ?? True !! False;
    }
}
