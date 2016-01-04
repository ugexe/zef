class Zef::Distribution is Distribution {
    # missing from Distribution
    has $.api = '';
    has @.build-depends;
    has @.test-depends;

    method is-installed(*@curlis is copy) { $ = IS-INSTALLED(self.identity) }

    method identity { $.Str }

    method hash {
        my %hash = callsame.append({ :$!api, :@!build-depends, :@!test-depends });
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
