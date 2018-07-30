use Zef;

class Zef::Service::Shell::LegacyBuild does Builder does Messenger {
    method !guess-build-file(IO() $prefix) { <Build.pm6 Build.pm>.map({ $prefix.child($_) }).first({ $_.e }) }

    method build-matcher($dist) {
        ($dist.meta-version // 0) == 0 and self!guess-build-file($dist.path)
    }
    method needs-build($dist) { self.build-matcher($dist) }

    method probe { True }

    # todo: write a real hooking implementation to CU::R::I
    # this is a giant ball of shit btw, but required for
    # all the existing distributions using Build.pm
    method build($dist, :@includes) {
        die "path does not exist: {$dist.path}" unless $dist.path.IO.e;

        # make sure to use -Ilib instead of -I. or else Linenoise's Build.pm will trigger a strange precomp error
        my $build-file = self!guess-build-file($dist.path).absolute;
        my $cmd        = "require '$build-file'; ::('Build').new.build('$dist.path.IO.absolute()') ?? exit(0) !! exit(1);";
        my @exec       = |($*EXECUTABLE, '-Ilib', |@includes.grep(*.defined).map({ "-I{$_}" }), '-e', "$cmd");

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
