use Zef;
use Zef::Distribution::Local;

# A 'Builder' that launches a process using a module provided in the 'builder' section of a provided distribution.

class Zef::Service::Shell::DistributionBuilder does Builder does Messenger {
    # Return true if this Builder understands the given meta data (has a 'builder' key) of the provided distribution
    method build-matcher(Zef::Distribution::Local $dist) { so $dist.builder }

    # Return true always since it just requires launching another raku process
    method probe { True }

    # Run the build step of this distribution
    # Launches a process to invoke whatever module is in the 'builder' field of the distributions META6.json while
    # passing the module the meta data of the distribution it is to build (allowing non-spec keys to be used by such
    # modules to allow consumers/authors to supply additional data)
    method build(Zef::Distribution::Local $dist, Str :@includes --> Bool:D) {
        die "path does not exist: {$dist.path}" unless $dist.path.IO.e;

        # todo: remove this ( and corresponding code in Zef::Distribution.build-depends-specs ) in the near future
        # Always use the full name 'Distribution::Builder::MakeFromJSON', not 'MakeFromJSON'
        my $dist-builder-compat = "$dist.builder()" eq 'MakeFromJSON'
            ?? "Distribution::Builder::MakeFromJSON"
            !!  "$dist.builder()";

        my $cmd = "exit((require ::(q|$dist-builder-compat|)).new("
                ~ ':meta(EVAL($*IN.slurp(:close)))'
                ~ ").build(q|$dist.path()|)"
                ~ '??0!!1)';

        my @exec = |($*EXECUTABLE.absolute, |@includes.grep(*.defined).map({ "-I{$_}" }), '-MMONKEY-SEE-NO-EVAL', '-e', "$cmd");

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
