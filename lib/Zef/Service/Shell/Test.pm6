use Zef;
use Zef::Utils::FileSystem;

# A simple 'Tester' that uses the raku executable to directly run test files

class Zef::Service::Shell::Test does Tester does Messenger {
    # Return true if this Tester understands the given uri/path
    method test-matcher($path --> Bool:D) { return True }

    # Returns true always since it just uses $*EXECUTABLE
    method probe(--> Bool:D) { True }

    # Test the given paths t/ directory using any provided @includes
    method test(IO() $path, :@includes --> Bool:D) {
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

        return so @results.all;
    }
}
