use Zef::Distribution::DependencySpecification;

# "is Distribution" because CU::R::I.install(Distribution $dist) requires it to be the core
# Distribution (cant just add `role Distribution { }; class Zef::Distribution does Distribution`
# as it will still not pass the parameter type validation on `Distribution`. It must actually
# subclass the core Distribution itself, which is also why some attributes are left defined
# in Distribution itself instead of Zef::Distribution (@.depends is already an attribute of
# Distribution for example, so we don't have a `has @.depends`)
class Zef::Distribution is Distribution is Zef::Distribution::DependencySpecification {
    # missing from Distribution
    has $.license;
    has @.build-depends;
    has @.test-depends;
    has @.resources;
    has @!provides-specs;

    # attach arbitrary data, like for topological sort, that won't be saved on install
    has %.metainfo is rw;

    method BUILDALL(|) {
        my $self = callsame;
        # Distribution.new(|%meta6) causes fields like `"depends": [1, 2, 3]` to
        # get assigned such that `Distribution.depends.perl` -> `([1,2,3])` instead
        # of just `[1, 2, 3]`. Because its nice to pass in |%meta to the constructor
        # we'll just flatten them manually instead of writing a better constructor
        @.depends       = @.depends.flatmap(*.flat);
        @!test-depends  = @!test-depends.flatmap(*.flat);
        @!build-depends = @!build-depends.flatmap(*.flat);
        @!resources     = @!resources.flatmap(*.flat);
        $self;
    }

    # Note: current hacky implementation will not work on a dist that has no `provides`
    # since the is-installed lookup is currently just `use Some::Module;`, so if a dist
    # `Foo` contains just bin scripts then `use Foo;` would always fail (and thus always
    # considered not installed)
    method is-installed(*@curlis is copy) {
        return True if IS-INSTALLED(self.identity);

        # EVALing a dist name doesn't really tell us if its *not* installed
        # since a dist name doesn't have to match up to any of its modules
        for self.provides.keys -> $provides {
            # If a `provides` module name doesn't include a ver/auth/api
            # then default them to the providing dist's values
            my %hash = IDENTITY2HASH($provides);
            next if self.name eq %hash<name>;
            %hash<ver>  //= self.ver;
            %hash<auth> //= self.auth;
            %hash<api>  //= self.api;
            my $provides-identity = HASH2IDENTITY(%hash);
            return ?IS-INSTALLED($provides-identity);
        }

        False
    }

    method identity { $.Str() }

    # make matching dependency names against a dist easier
    # when sorting the install order from the meta hash
    method depends-specs       {
        eager gather for @.depends {
            my $ds = Zef::Distribution::DependencySpecification.new($_);
            take $ds;
        }
    }
    method build-depends-specs {
        eager gather for @.build-depends {
            my $ds = Zef::Distribution::DependencySpecification.new($_);
            take $ds;
        }
    }
    method test-depends-specs  {
        eager gather for @.test-depends {
            my $ds = Zef::Distribution::DependencySpecification.new($_);
            take $ds;
        }
    }

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

    # Add new entries missing from original Distribution.hash
    method hash {
        my %hash = callsame.append({ :$.api, :@!build-depends, :@!test-depends, :@!resources });
        %hash<identity> = $.Str;
        %hash<license>  = $.license;
        %hash;
    }

    # use Distribution's .ver but filter off a leading 'v'
    method ver { callsame.subst(/^v/, '') }

    # The identity genered by Distribution's Str() does not always parse in `use` statements
    method Str() {
        $ = HASH2IDENTITY({ :name($.name), :ver($.ver), :auth($.auth), :api($.api) });
    }

    method id() {
        use nqp;
        return nqp::sha1(self.Str());
    }

    method WHICH(Zef::Distribution:D:) { "{self.^name}|{self.Str()}" }
}

# xxx: temporary until a core solution is available
sub IS-INSTALLED($identity) {
    use MONKEY-SEE-NO-EVAL;
    use Zef::Shell;

    try {
        my $perl6 = $*EXECUTABLE;
        my $cwd   = $*TMPDIR; # change cwd for script below so $*CWD/lib is not accidently considered
        my $is-installed-script = "use $identity;";
        my $proc = zrun($perl6, '-e', $is-installed-script, :$cwd, :out, :err);
        my $out = $proc.out.slurp-rest;
        my $err = $proc.err.slurp-rest;
        $proc.out.close;
        $proc.err.close;

        ?$proc
    }
    return (not defined $!) ?? True !! False;
}

# allow easier sorting of an array of Distribution objects by version
# (intended that the rest of the identity is the same)
multi sub infix:<cmp>(Distribution $lhs, Distribution $rhs) is export {
    Version.new($lhs.ver) cmp Version.new($rhs.ver)
}
