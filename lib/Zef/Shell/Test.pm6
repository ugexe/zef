use Zef;
use Zef::Shell;
use Zef::Utils::FileSystem;

class Zef::Shell::Test is Zef::Shell does Tester does Messenger {
    method test-matcher($path) { True }

    method probe { $ = True }

    method test($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my @test-files = grep *.extension eq 't',
            list-paths($path.IO.child('t').absolute, :f, :!d, :r).sort;

        my @results = eager gather for @test-files -> $test-file {
            # many tests are written with the assumption that $*CWD will be their distro's base directory
            # so we have to hack around it so people can still (rightfully) pass absolute paths to `.test`
            my $relpath   = $test-file.relative($path);
            $.stdout.emit("[Zef::Shell::Test] Testing: {$relpath}");

            my $env = %*ENV;
            my @cur-p6lib  = $env<PERL6LIB>.?chars ?? $env<PERL6LIB>.split($*DISTRO.cur-sep) !! ();
            my @new-p6lib  = $path.IO.child('lib').absolute, |@includes;
            $env<PERL6LIB> = (|@new-p6lib, |@cur-p6lib).join($*DISTRO.cur-sep);

            # XXX: -Ilib/.precomp is a workaround for rakudo precomp locking bug
            # It generates it .precomp in lib/.precomp/.precomp so the default
            # precomp folder being in use/locked won't affect our custom prefix copy
            my $proc = zrun($*EXECUTABLE, '-Ilib/.precomp', $relpath, :cwd($path), :$env, :out, :err);

            $.stdout.emit($_) for $proc.out.lines;
            $.stderr.emit($_) for $proc.err.lines;
            $proc.out.close;
            $proc.err.close;
            take $proc;
        }
        @test-files.elems ?? ?@results.map(?*) !! True;
    }
}
