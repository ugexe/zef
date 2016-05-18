use Zef;
use Zef::Utils::FileSystem;
require ::("TAP::Harness");

class Zef::Test::TAPHarness does Tester does Messenger {
    method test-matcher($path) { True }

    method probe { state $probe = (so try { ::("TAP::Harness") !~~ Failure }) == True; }

    method test($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my @test-paths = list-paths($path.IO.child('t')).grep(*.extension eq 't').sort;
        return True unless +@test-paths;

        my $cwd = $*CWD;
        my $result = try {
            chdir($path);
            my @incdirs  = $path.IO.child('lib').absolute, |@includes;
            my @handlers = ::("TAP::Harness::SourceHandler::Perl6").new(:@incdirs);
            my $parser   = ::("TAP::Harness").new(:@handlers);
            my $promise  = $parser.run(@test-paths>>.relative($path));
            $promise.result;
        }
        chdir($cwd);

        # $.stdout.emit($_);
        # $.stderr.emit($_);
        $ = $result.failed == 0;
    }
}
