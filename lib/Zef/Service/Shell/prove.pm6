use Zef;
use Zef::Shell;

class Zef::Service::Shell::prove is Zef::Shell does Tester does Messenger {
    method test-matcher($path) { True }

    method probe {
        state $prove-probe;
        once {
            # `prove --help` has exitcode == 1 unlike most other processes
            # so it requires a more convoluted probe check
            try {
                my $proc = zrun('prove', '--help', :out, :err);
                my @out  = $proc.out.lines;
                my @err  = $proc.err.lines;
                $proc.out.close;
                $proc.err.close;
                CATCH {
                    when X::Proc::Unsuccessful {
                        $prove-probe = True if $proc.exitcode == 1 && @out.first(*.contains("-exec"));
                    }
                    default { return False }
                }
            }
        }
        ?$prove-probe;
    }

    method test($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my $test-path = $path.IO.child('t');
        return True unless $test-path.e;

        my $env = %*ENV;
        my @cur-p6lib  = $env<PERL6LIB>.?chars ?? $env<PERL6LIB>.split($*DISTRO.cur-sep) !! ();
        my @new-p6lib  = $path.IO.child('lib').absolute, |@includes;
        $env<PERL6LIB> = (|@new-p6lib, |@cur-p6lib).join($*DISTRO.cur-sep);

        # XXX: -Ilib/.precomp is a workaround for rakudo precomp locking bug
        # It generates it .precomp in lib/.precomp/.precomp so the default
        # precomp folder being in use/locked won't affect our custom prefix copy
        my $proc = zrun('prove', '-r', '-e', qq|$*EXECUTABLE -Ilib/.precomp|,
            $test-path.relative($path), :cwd($path), :$env, :out, :err);

        $.stdout.emit($_) for $proc.out.lines;
        $.stderr.emit($_) for $proc.err.lines;
        $proc.out.close;
        $proc.err.close;

        $ = ?$proc;
    }
}
