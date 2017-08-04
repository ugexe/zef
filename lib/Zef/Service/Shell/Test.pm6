use Zef;
use Zef::Utils::FileSystem;

class Zef::Service::Shell::Test does Tester does Messenger {
    method test-matcher($path) { True }

    method probe { True }

    method test($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;

        my $test-path = $path.IO.child('t');
        return True unless $test-path.e;
        my @test-files = grep *.extension eq 't',
            list-paths($test-path.absolute, :f, :!d, :r).sort;
        return True unless +@test-files;

        my @results = @test-files.map: -> $test-file {
            # many tests are written with the assumption that $*CWD will be their distro's base directory
            # so we have to hack around it so people can still (rightfully) pass absolute paths to `.test`
            my $relpath   = $test-file.relative($path);

            my $env = %*ENV;
            my @cur-p6lib  = $env<PERL6LIB>.?chars ?? $env<PERL6LIB>.split($*DISTRO.cur-sep) !! ();
            my @new-p6lib  = $path.IO.absolute, $path.IO.child('lib').absolute, |@includes;
            $env<PERL6LIB> = (|@new-p6lib, |@cur-p6lib).join($*DISTRO.cur-sep);

            my $proc = zrun(:cwd($path), :$env, :out, :err,
                $*EXECUTABLE.absolute, $relpath);
            $proc.out.Supply.tap: { $.stdout.emit($_) };
            $proc.err.Supply.tap: { $.stderr.emit($_) };
            $proc.out.close;
            $proc.err.close;

            $proc.so;
        }

        return @results.all.so
    }
}
