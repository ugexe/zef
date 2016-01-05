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

            # many tests are written with the assumption that $*CWD will be their distro's base directory
            # so we have to hack around it so people can still (rightfully) pass absolute paths to `.test`
            my $base-path = $test-file.parent.parent.absolute.IO;

            my $proc = zrun($*EXECUTABLE, '--ll-exception', '-Ilib', $test-file.relative($base-path),
                :cwd(~$base-path), :out, :err);

            .say for $proc.out.lines;
            $proc.out.close;
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
