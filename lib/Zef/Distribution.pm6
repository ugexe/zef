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
    has %.support;

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

    # make matching dependency names against a dist easier
    # when sorting the install order from the meta hash
    method depends-specs       {
        gather for @.depends.grep(*.defined) {
            take Zef::Distribution::DependencySpecification.new($_);
        }
    }
    method build-depends-specs {
        gather for @.build-depends.grep(*.defined) {
            take Zef::Distribution::DependencySpecification.new($_);
        }
    }
    method test-depends-specs  {
        gather for @.test-depends.grep(*.defined) {
            take Zef::Distribution::DependencySpecification.new($_);
        }
    }

    # make locating a module that is part of a distribution (ex. URI::Escape of URI) easier.
    # it doesn't need to be a hash mapping as its just for matching
    method provides-specs {
        cache gather for %(self.hash<provides>) {
            # if $spec.name is not defined then .key (the module name of the current provides)
            # is not a valid module name (according to Zef::Identity grammar anyway). I ran into
            # this problem with `NativeCall::Errno` where one of the provides was: `X:NativeCall::Errorno`
            # The single colon cannot just be fixed to DWIM because that could just as easily denote
            # an identity part (identity parts are separated by a *single* colon; double colon is left alone)
            my $spec = Zef::Distribution::DependencySpecification.new(.key);
            take $spec if defined($spec.name);
        }
    }

    method provides-spec-matcher($spec) { $ = self.provides-specs.first({ ?$_.spec-matcher($spec) }) }

    proto method contains-spec(|) {*}
    multi method contains-spec(Str $spec)
        { samewith( Zef::Distribution::DependencySpecification.new($spec) ) }
    multi method contains-spec(Zef::Distribution::DependencySpecification $spec)
        { so self.spec-matcher($spec) || self.provides-spec-matcher($spec)  }

    # Add new entries missing from original Distribution.hash
    method hash {
        my %hash = callsame.append({ :$.api, :@!build-depends, :@!test-depends, :@!resources });
        %hash<license>  = $.license;
        %hash<support>  = %.support;

        # debugging stuff
        %hash<identity> = $.identity;
        %hash<id>       = $.id;
        %hash<Str>      = $.Str();

        %hash;
    }

    # use Distribution's .ver but filter off a leading 'v'
    method ver { my $v = callsame; $v.subst(/^v/, '') }

    method id() { use nqp; $ = nqp::sha1(self.Str()) }

    method WHICH(Zef::Distribution:D:) { "{self.^name}|{self.Str()}" }
}

# allow easier sorting of an array of Distribution objects by version
# (intended that the rest of the identity is the same)
multi sub infix:<cmp>(Distribution $lhs, Distribution $rhs) is export {
    Version.new($lhs.ver) cmp Version.new($rhs.ver)
}
