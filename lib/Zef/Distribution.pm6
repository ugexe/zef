use Zef::Distribution::DependencySpecification;

class Zef::Distribution is Distribution is Zef::Distribution::DependencySpecification {
    # missing from Distribution
    has @.build-depends;
    has @.test-depends;
    has @.resources;
    has @!provides-specs;

    method BUILDALL(|) {
        my $self = callsame;
        @.depends       = @.depends.flatmap(*.flat);
        @!test-depends  = @!test-depends.flatmap(*.flat);
        @!build-depends = @!build-depends.flatmap(*.flat);
        @!resources     = @!resources.flatmap(*.flat);
        $self;
    }

    # attach arbitrary data, like for topological sort, that won't be saved on install
    has %.metainfo is rw;

    method is-installed(*@curlis is copy) { $ = IS-INSTALLED(self.identity) }

    method identity { $.Str()  }

    # make matching dependency names against a dist easier
    # when sorting the install order from the meta hash
    method depends-specs       { @.depends.map:       { $ = Zef::Distribution::DependencySpecification.new($_) } }
    method build-depends-specs { @.build-depends.map: { $ = Zef::Distribution::DependencySpecification.new($_) } }
    method test-depends-specs  { @.test-depends.map:  { $ = Zef::Distribution::DependencySpecification.new($_) } }

    # make locating a module that is part of a distribution (ex. URI::Escape of URI) easier.
    # it doesn't need to be a hash mapping as its just for matching
    method provides-specs {
        @!provides-specs = self.hash<provides>.hash.map: { $ = Zef::Distribution::DependencySpecification.new(.key) }
    }

    method provides-spec-matcher($spec) {
        so self.provides-specs.grep({ ?$_.spec-matcher($spec) }).elems;
    }

    method contains-spec($spec) {
        so self.spec-matcher($spec) || self.provides-spec-matcher($spec)
    }

    method hash {
        # missing from Distribution.hash
        my %hash = callsame.append({ :$.api, :@!build-depends, :@!test-depends, :@!resources });
        %hash<id>       = $.id;
        %hash<identity> = $.Str;
        %hash;
    }

    method WHICH(Zef::Distribution:D:) { "{self.^name}|{self.Str()}" }
}

sub IS-INSTALLED($identity) {
    use MONKEY-SEE-NO-EVAL;
    try {
        CATCH { default { return False; }; };
        my %parts = IDENTITY2HASH($identity);
        my $require = %parts<name>
            ~ ((%parts<ver>  // '' ) ne ('*' | '')?? ":ver<{%parts<ver>}>"   !! '')
            ~ ((%parts<auth> // '' ) ne ('*' | '') ?? ":auth<{%parts<auth>}>" !! '')
            ~ ((%parts<api>  // '' ) ne ('*' | '') ?? ":api<{%parts<api>}>"   !! '');
        #EVAL qq|use $require;|;
        # can't use :ver inside EVAL yet, and require ignores it
        EVAL qq|%parts<name>|;
        return True;
    }
}
