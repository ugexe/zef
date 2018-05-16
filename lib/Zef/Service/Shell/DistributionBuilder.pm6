use Zef;

class Zef::Service::Shell::DistributionBuilder does Builder does Messenger {
    method build-matcher($dist) { ($dist.meta-version // 0) == 1 }
    method needs-build($dist) { self.build-matcher($dist) and $dist.builder }

    method probe { True }

    method build($dist, :@includes) {
        die "path does not exist: {$dist.path}" unless $dist.path.IO.e;

        my $cmd = "exit((require ::(q|Distribution::Builder::$dist.builder()|)).new("
                ~ ':meta(EVAL($*IN.slurp(:close)))'
                ~ ").build(q|$dist.path()|)"
                ~ '??0!!1)';

        my @exec = |($*EXECUTABLE, '-I.', |@includes.grep(*.defined).map({ "-I{$_}" }), '-MMONKEY-SEE-NO-EVAL', '-e', "$cmd");

        $.stdout.emit("Command: {@exec.join(' ')}");

        my $ENV := %*ENV;
        my $passed;
        react {
            my $proc = zrun-async(@exec, :w);
            whenever $proc.stdout.lines { $.stdout.emit($_) }
            whenever $proc.stderr.lines { $.stderr.emit($_) }
            whenever $proc.start(:$ENV, :cwd($dist.path)) { $passed = $_.so }
            whenever $proc.print($dist.meta.hash.perl) { $proc.close-stdin }
        }
        return $passed;
    }
}
