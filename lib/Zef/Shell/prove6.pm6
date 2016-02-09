use Zef;
use Zef::Shell;

class Zef::Shell::prove6 is Zef::Shell does Tester does Messenger {
    method test-matcher($path) { True }

    method probe {
        state $prove6-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            so zrun('prove6', '--help');
        }
        ?$prove6-probe;
    }

    method test($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my $test-path = $path.IO.child('t');
        return True unless $test-path.e;
        $.stdout.emit("[Zef::Shell::prove6] Testing: {$test-path.absolute}");

        my $env = %*ENV;
        my @cur-p6lib  = $env<PERL6LIB>.?chars ?? $env<PERL6LIB>.split($*DISTRO.cur-sep) !! ();
        my @new-p6lib  = $path.IO.child('lib').absolute, |@includes;
        $env<PERL6LIB> = (|@new-p6lib, |@cur-p6lib).join($*DISTRO.cur-sep);

        # XXX: -Ilib/.precomp is a workaround for rakudo precomp locking bug
        # It generates it .precomp in lib/.precomp/.precomp so the default
        # precomp folder being in use/locked won't affect our custom prefix copy
        my $proc = zrun('prove6', '-Ilib/.precomp', '-v', '-r',
            $test-path.relative($path), :cwd($path), :$env, :out, :err);

        $.stdout.emit($_) for $proc.out.lines;
        $.stderr.emit($_) for $proc.err.lines;
        $proc.out.close;
        $proc.err.close;
        $ = ?$proc;
    }
}
