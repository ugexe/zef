use Zef::Distribution::DependencySpecification;

class Zef::Distribution is Distribution {
    # missing from Distribution
    has @.build-depends;
    has @.test-depends;
    has %.meta is rw; # keep track of topological sort stuff for now

    method is-installed(*@curlis is copy) { $ = IS-INSTALLED(self.identity) }

    method identity { $.Str }

    # make matching dependency names against a dist easier
    # when sorting the install order from the meta hash
    method depends-specs       { @.depends.map(*.flat).flat.map({       Zef::Distribution::DependencySpecification.new($_) }) }
    method build-depends-specs { @.build-depends.map(*.flat).flat.map({ Zef::Distribution::DependencySpecification.new($_) }) }
    method test-depends-specs  { @.test-depends.map(*.flat).flat.map({  Zef::Distribution::DependencySpecification.new($_) }) }

    method hash {
        my %hash = callsame.append({ :$.api, :@!build-depends, :@!test-depends });
        %hash<depends>       .= Slip;
        %hash<build-depends> .= Slip;
        %hash<test-depends>  .= Slip;
        %hash<id> = $.id;
        %hash<identity> = $.Str;
        %hash;
    }

    method WHICH(Zef::Distribution:D:) { "{self.^name}|{self.Str()}" }
}

sub IS-INSTALLED($identity) {
    use MONKEY-SEE-NO-EVAL;
    try {
        CATCH { default { return False; }; };
        #EVAL "use {$identity};";
        EVAL qq|use {$identity.subst(/"::"/,"  ", :g).split(/":"/)[0].subst(/\s\s/, "::", :g)};|;
        return True;
    }
}
