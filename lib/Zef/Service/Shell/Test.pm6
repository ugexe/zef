use Zef;
use Zef::Utils::FileSystem;

class Zef::Service::Shell::Test does Tester does Messenger {
    method test-matcher($path) { True }

    method probe { True }

    method test(IO() $path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;

        my $test-path = $path.child('t');
        return True unless $test-path.e;
        my @test-files = grep *.extension eq any('rakutest', 't', 't6'),
            list-paths($test-path.absolute, :f, :!d, :r).sort;
        return True unless +@test-files;

        my @results = @test-files.map: -> $test-file {
            # many tests are written with the assumption that $*CWD will be their distro's base directory
            # so we have to hack around it so people can still (rightfully) pass absolute paths to `.test`
            my $relpath   = $test-file.relative($path);

            my %ENV = %*ENV;
            my @cur-p6lib  = %ENV<PERL6LIB>.?chars ?? %ENV<PERL6LIB>.split($*DISTRO.cur-sep) !! ();
            my @new-p6lib  = $path.absolute, |@includes;
            %ENV<PERL6LIB> = (|@new-p6lib, |@cur-p6lib).join($*DISTRO.cur-sep);

            my $passed;
            react {
                my $proc = zrun-async($*EXECUTABLE.absolute, $relpath);
                whenever $proc.stdout.lines { $.stdout.emit($_) }
                whenever $proc.stderr.lines { $.stderr.emit($_) }
                whenever $proc.start(:%ENV, :cwd($path)) { $passed = $_.so }
            }
            $passed;
        }

        return @results.all.so
    }
}
