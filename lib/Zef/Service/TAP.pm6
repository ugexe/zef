use Zef;
use Zef::Utils::FileSystem;

class Zef::Service::TAP does Tester does Messenger {
    method test-matcher($path) { True }

    method probe { state $probe = (try require TAP) !~~ Nil ?? True !! False }

    method test($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;

        my $test-path = $path.IO.child('t');
        return True unless $test-path.e;
        my @test-files = grep *.extension eq 't',
            list-paths($test-path.absolute, :f, :!d, :r).sort;
        return True unless +@test-files;

        my $stdout = $*OUT;
        my $stderr = $*ERR;
        my $out;
        my $err;
        my $cwd = $*CWD;
        my $result = do {
            require TAP;
            chdir($path);
            my $*OUT = class {
                also is IO::Handle;
                method print(*@_) { $out ~= @_.join("\n") }
                method flush {}
            }.new;
            my $*ERR = class {
                also is IO::Handle;
                method print(*@_) { $err ~= @_.join("\n") }
                method flush {}
            }.new;
            my @incdirs  = $path.IO.child('lib').absolute, |@includes;
            my @handlers = ::("TAP::Harness::SourceHandler::Perl6").new(:@incdirs);
            my $parser   = ::("TAP::Harness").new(:@handlers);
            my $promise  = $parser.run(@test-files>>.relative($path));
            $promise.result;
        }
        $*OUT = $stdout;
        $*ERR = $stderr;
        $.stdout.emit($out);
        $.stderr.emit($err);
        chdir($cwd);

        $result.failed == 0 && not $result.errors ?? True !! False;
    }
}