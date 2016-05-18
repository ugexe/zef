use Zef;
use Zef::Utils::FileSystem;

class Zef::Test::TAPHarness does Tester does Messenger {
    method test-matcher($path) { True }

    method probe { state $probe = (try require TAP) !~~ Nil ?? True !! False }

    method test($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my @test-files = grep *.extension eq 't',
            list-paths($path.IO.child('t').absolute, :f, :!d, :r).sort;
        return True unless +@test-files;

        my $cwd = $*CWD;
        my $result = try {
            chdir($path);
            my @incdirs  = $path.IO.child('lib').absolute, |@includes;
            my @handlers = ::("TAP::Harness::SourceHandler::Perl6").new(:@incdirs);
            my $parser   = ::("TAP::Harness").new(:@handlers);
            my $promise  = $parser.run(@test-files>>.relative($path));
            $promise.result;
        }
        chdir($cwd);

        # $.stdout.emit($_);
        # $.stderr.emit($_);
        $ = $result.failed == 0;
    }
}
