use Zef;
use Zef::Shell;

class Zef::Shell::Test is Zef::Shell does Tester {
    method test-matcher($path) { True }

    method probe { $ = True }

    method test($path) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my @test-files = self.find-tests($path);

        my @results = eager gather for @test-files -> $test-file {
            # many tests are written with the assumption that $*CWD will be their distro's base directory
            # so we have to hack around it so people can still (rightfully) pass absolute paths to `.test`
            my $rel-test  = $test-file.relative($path);
            $.stdout.emit("[DEBUG] Testing: {$rel-test}");
            my $proc = zrun($*EXECUTABLE, '-Ilib', $rel-test, :cwd($path), :out, :err);
            $.stdout.emit($_) for $proc.out.lines;
            $.stderr.emit($_) for $proc.err.lines;
            $proc.out.close;
            $proc.err.close;
            take $proc;
        }
        @test-files.elems ?? ?@results.map(?*) !! True;
    }

    method find-tests($path) {
        my @stack = $path.IO.child('t').absolute;
        my $perl-files := gather while ( @stack ) {
            my $current = @stack.pop;
            take $current.IO if ($current.IO.f && $current.IO.extension ~~ rx:i/t$/);
            @stack.append(dir($current)>>.path) if $current.IO.d;
        }
    }
}
