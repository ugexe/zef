use Zef;
use Zef::Shell;
use Zef::Utils::FileSystem;

class Zef::Service::Shell::Test is Zef::Shell does Tester does Messenger {
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

            my $env = %*ENV;
            my @cur-p6lib  = $env<PERL6LIB>.?chars ?? $env<PERL6LIB>.split($*DISTRO.cur-sep) !! ();
            my @new-p6lib  = $path.IO.child('lib').absolute, |@includes;
            $env<PERL6LIB> = (|@new-p6lib, |@cur-p6lib).join($*DISTRO.cur-sep);

            my $proc = zrun($*EXECUTABLE, $relpath, :cwd($path), :$env, :out, :err);

            my @err = $proc.err.lines;
            my @out = $proc.out.lines;

            $.stdout.emit($_) for |@out;;
            $.stderr.emit($_) for |@err;

            $ = $proc.out.close unless +@err;
            $ = $proc.err.close;

            take ?$proc;
        }
    }
}
