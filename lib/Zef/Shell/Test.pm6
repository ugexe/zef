use Zef;
use Zef::Shell;

class Zef::Shell::Test is Zef::Shell does Tester does Messenger {
    method test-matcher($path) { True }

    method probe { $ = True }

    method test($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my @test-files = self.find-tests($path);

        my @results = eager gather for @test-files -> $test-file {
            # many tests are written with the assumption that $*CWD will be their distro's base directory
            # so we have to hack around it so people can still (rightfully) pass absolute paths to `.test`
            my $rel-test  = $test-file.relative($path);
            $.stdout.emit("[Zef::Shell::Test] Testing: {$rel-test}");

            my $env = %*ENV;
            my @cur-p6lib  = $env<PERL6LIB>.?chars ?? $env<PERL6LIB>.split($*DISTRO.cur-sep) !! ();
            my @new-p6lib  = $path.IO.child('lib').absolute, |@includes;
            $env<PERL6LIB> = (|@new-p6lib, |@cur-p6lib).join($*DISTRO.cur-sep);

            # XXX: -Ilib/.precomp is a workaround for rakudo precomp locking bug
            # It generates it .precomp in lib/.precomp/.precomp so the default
            # precomp folder being in use/locked won't affect our custom prefix copy
            my $proc = zrun($*EXECUTABLE, '-Ilib/.precomp', $rel-test, :cwd($path), :$env, :out, :err);

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
        my $test-files := gather while ( @stack ) {
            my $current = @stack.pop;
            take $current.IO if ($current.IO.f && $current.IO.extension ~~ rx:i/t$/);
            @stack.append(dir($current)>>.path) if $current.IO.d;
        }
    }
}
