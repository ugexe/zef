use Zef;

class Zef::Service::Shell::prove does Tester does Messenger {
    method test-matcher($path) { True }

    method probe {
        state $probe;
        once {
            # `prove --help` has exitcode == 1 unlike most other processes
            # so it requires a more convoluted probe check
            try {
                my $proc = $*DISTRO.is-win
                    ?? zrun('prove.bat', '--help', :out, :!err)
                    !! zrun('prove', '--help', :out, :!err);
                my @out  = $proc.out.lines;
                $proc.out.close;
                CATCH {
                    when X::Proc::Unsuccessful {
                        $probe = True if $proc.exitcode == 1 && @out.first(*.contains("-exec" | "Mac OS X"));
                    }
                    default { return False }
                }
            }
        }
        ?$probe;
    }

    method test(IO() $path, :@includes) {
        die "cannot test path that does not exist: {$path}" unless $path.e;
        my $test-path = $path.child('t');
        return True unless $test-path.e;

        my %ENV = %*ENV;
        my @cur-p6lib  = %ENV<PERL6LIB>.?chars ?? %ENV<PERL6LIB>.split($*DISTRO.cur-sep) !! ();
        my @new-p6lib  = $path.absolute, |@includes;
        %ENV<PERL6LIB> = (|@new-p6lib, |@cur-p6lib).join($*DISTRO.cur-sep);

        my $passed;
        react {
            my $proc = $*DISTRO.is-win
                ?? Proc::Async.new(:win-verbatim-args, 'prove.bat', '--ext',
                    '.rakutest', '--ext', '.t', '--ext', '.t6', '-r', '-e',
                    '"' ~ $*EXECUTABLE.absolute ~ '"',
                    '"' ~ $test-path.relative($path) ~ '"')
                !! Proc::Async.new('prove', '--ext', '.rakutest', '--ext',
                    '.t', '--ext', '.t6', '-r', '-e', $*EXECUTABLE.absolute,
                    $test-path.relative($path));
            whenever $proc.stdout.lines { $.stdout.emit($_) }
            whenever $proc.stderr.lines { $.stderr.emit($_) }
            whenever $proc.start(:%ENV, :cwd($path)) { $passed = $_.so }
        }
        return $passed;
    }
}
