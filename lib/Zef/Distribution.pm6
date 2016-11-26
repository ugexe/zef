use Zef;
use Zef::Distribution::DependencySpecification;

# XXX: Needed for backwards compat. Will be removed when I rework Distribution related items
class Distribution::DEPRECATED {
    has $.name;
    has $.auth;
    has $.author;
    has $.authority;
    has $.api;
    has $.ver;
    has $.version;
    has $.description;
    has @.depends;
    has %.provides;
    has %.files;
    has $.source-url;
    method auth { $!auth // $!author // $!authority }
    method ver  { $!ver // $!version }
    method hash {
        {
            :$!name,
            :$.auth,
            :$.ver,
            :$!description,
            :@!depends,
            :%!provides,
            :%!files,
            :$!source-url,
        }
    }
    method Str() {
        return "{$.name}:ver<{$.ver  // ''}>:auth<{$.auth // ''}>:api<{$.api // ''}>";
    }
    method id() {
        use nqp;
        return nqp::sha1(self.Str);
    }
}

# NOTE: Everything referencing `Distribution` in the below comment now refers to `Distribution::DEPRECAED`
# "is Distribution" because CU::R::I.install(Distribution $dist) requires it to be the core
# Distribution (cant just add `role Distribution { }; class Zef::Distribution does Distribution`
# as it will still not pass the parameter type validation on `Distribution`. It must actually
# subclass the core Distribution itself, which is also why some attributes are left defined
# in Distribution itself instead of Zef::Distribution (@.depends is already an attribute of
# Distribution for example, so we don't have a `has @.depends`)
class Zef::Distribution is Distribution::DEPRECATED is Zef::Distribution::DependencySpecification {
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

    method provides-spec-matcher($spec, :$strict) { self.provides-specs.first({ ?$_.spec-matcher($spec, :$strict) }) }

    proto method contains-spec(|) {*}
    multi method contains-spec(Str $spec, |c)
        { samewith( Zef::Distribution::DependencySpecification.new($spec, |c) ) }
    multi method contains-spec(Zef::Distribution::DependencySpecification $spec, Bool :$strict)
        { so self.spec-matcher($spec, :$strict) || self.provides-spec-matcher($spec, :$strict)  }

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

    method WHICH(Zef::Distribution:D:) { "{self.^name}|{self.Str()}" }

    # For now we will use $dist.compat in spots where we pass to rakudo and there
    # are Distribution constraints (install and uninstall?). This provides backwards compatibility
    # until a more robust solution is worked out
    method compat {
        $PRE-DIST-INTERFACE
            ?? Distribution.new(|$.hash)
            !! (::("Distribution::Hash").new(self.?meta || $.hash, :prefix(self.?IO // $*CWD)) but role {
                method name { self.meta<name> }
                method ver  { self.meta<ver> // self.meta<version> }
                method auth { self.meta<auth> // self.meta<authority> // self.meta<author> }
            });
    }
}

# allow easier sorting of an array of Distribution objects by version
# (intended that the rest of the identity is the same)
multi sub infix:<cmp>(Distribution $lhs, Distribution $rhs) is export {
    Version.new($lhs.ver) cmp Version.new($rhs.ver)
}
