use Zef;
use Zef::Shell;

class Zef::Shell::Test is Zef::Shell does Tester does Messenger {
    method test-matcher($path) { so self.find-tests($path).elems }

    method probe { $ = True }

    method test($path) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my @test-files = self.find-tests($path);

        my @results = gather for @test-files -> $test-file {
            say "[DEBUG] Testing: $test-file";
            my $proc = zrun('perl6', '--ll-exception', '-Ilib', $test-file, :cwd($test-file.IO.parent.IO.parent), :out);
            my $nl   = Buf.new(10).decode;
            .say for $proc.out.lines;
            take $proc;
        }

        ?@results.map(?*);
    }

    method find-tests($path) {
        @ = ($path.IO.d && $path.IO.basename eq 't')
            ?? $path.IO.dir.grep(*.IO.extension.lc eq 't')
            !! ($path.IO.f && $path.IO.extension.lc eq 't'
                ?? $path
                !! ($path.IO.child('t').IO.e && $path.IO.child('t').IO.d
                    ?? $path.IO.child('t').IO.dir.grep(*.IO.extension.lc eq 't')
                    !! Nil) );
    }
}
