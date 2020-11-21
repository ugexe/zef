use Zef;
use Zef::Distribution::Local;

# A simple 'Builder' that launches a 'Build.rakumod' file of the provided distribution with the raku executable

class Zef::Service::Shell::LegacyBuild does Builder does Messenger {
    # Get the path of the Build file that will be executaed
    method !guess-build-file(IO() $prefix --> IO::Path) { return <Build.rakumod Build.pm6 Build.pm>.map({ $prefix.child($_) }).first({ $_.e }) }

    # Return true if this Builder understands the given uri/path of the provided distribution
    method build-matcher(Zef::Distribution::Local $dist --> Bool:D) { return so self!guess-build-file($dist.path) }

    # Return true always since it just requires launching another raku process
    method probe(--> Bool:D) { True }

    # Run the Build.rakumod of the given distribution
    # todo: write a real hooking implementation to CU::R::I
    # this is a giant ball of shit btw, but required for
    # all the existing distributions using Build.pm
    method build(Zef::Distribution::Local $dist, Str :@includes --> Bool:D) {
        die "path does not exist: {$dist.path}" unless $dist.path.IO.e;

        # make sure to use -Ilib instead of -I. or else Linenoise's Build.pm will trigger a strange precomp error
        my $build-file = self!guess-build-file($dist.path).absolute;
        my $cmd        = "require '$build-file'; ::('Build').new.build('$dist.path.IO.absolute()') ?? exit(0) !! exit(1);";
        my @exec       = |($*EXECUTABLE.absolute, |@includes.grep(*.defined).map({ "-I{$_}" }), '-e', "$cmd");

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
