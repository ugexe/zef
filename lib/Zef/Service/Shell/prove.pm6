use Zef;

class Zef::Service::Shell::prove does Tester does Messenger {
    method test-matcher($path) { True }

    method probe {
        state $probe;
        once {
            # `prove --help` has exitcode == 1 unlike most other processes
            # so it requires a more convoluted probe check
            try {
                my $proc = run('prove', '--help', :out, :!err);
                $probe = True if $proc.exitcode == 0;
                $probe = True if $proc.exitcode == 1 && ?$proc.out.slurp.contains("-exec" | "Mac OS X");
            }
        }
        ?$probe;
    }

    method test($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my $test-path = $path.IO.child('t');
        return True unless $test-path.e;

        my $env = %*ENV;
        my @cur-p6lib  = $env<PERL6LIB>.?chars ?? $env<PERL6LIB>.split($*DISTRO.cur-sep) !! ();
        my @new-p6lib  = $path.IO.child('lib').absolute, |@includes;
        $env<PERL6LIB> = (|@new-p6lib, |@cur-p6lib).join($*DISTRO.cur-sep);

        my $proc = run(:cwd($path), :$env, :out, :err,
            'prove', '-r', '-e', $*EXECUTABLE.absolute, $test-path.relative($path) );
        $proc.out.Supply.tap: { $.stdout.emit($_) };
        $proc.err.Supply.tap: { $.stderr.emit($_) };

        my $result = $proc.so;
        $proc.out.close;
        $proc.err.close;

        return $result;
    }
}
