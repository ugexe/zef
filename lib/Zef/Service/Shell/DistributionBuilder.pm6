use Zef;

class Zef::Service::Shell::DistributionBuilder does Builder does Messenger {
    method build-matcher($dist) { ($dist.meta-version // 0) == 1 }
    method needs-build($dist) { self.build-matcher($dist) and $dist.builder }

    method probe { True }

    method build($dist, :@includes) {
        die "path does not exist: {$dist.path}" unless $dist.path.IO.e;

        my $cmd  = "(require ::('Distribution::Builder::$dist.builder()')).new(meta => $dist.meta.perl()).build('$dist.path()') ?? exit(0) !! exit(1)";
        my @exec = |($*EXECUTABLE, '-I.', |@includes.grep(*.defined).map({ "-I{$_}" }), '-e', "$cmd");

        $.stdout.emit("Command: {@exec.join(' ')}");

        my $ENV := %*ENV;
        my $passed;
        react {
            my $proc = zrun-async(@exec);
            whenever $proc.stdout.lines { $.stdout.emit($_) }
            whenever $proc.stderr.lines { $.stderr.emit($_) }
            whenever $proc.start(:$ENV, :cwd($dist.path)) { $passed = $_.so }
        }
        return $passed;
    }
}
