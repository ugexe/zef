use Zef;
use Zef::Distribution::DependencySpecification;
use Zef::Utils::SystemQuery;

class Zef::Distribution does Distribution is Zef::Distribution::DependencySpecification {
    has $.meta-version;
    has $.name;
    has $.auth;
    has $.author;
    has $.authority;
    has $.api;
    has $.ver;
    has $.version;
    has $.description;
    has $.depends;
    has %.provides;
    has %.files;
    has $.source-url;
    has $.license;
    has $.build-depends;
    has $.test-depends;
    has @.resources;
    has %.support;
    has $.builder;

    has $.meta; # Holds a copy of the original meta data so we don't lose non-spec meta fields like 'build'

    # attach arbitrary data, like for topological sort, that won't be saved on install
    has %.metainfo is rw;

    method new(*%_) { self.bless(|%_, :meta(%_)) }

    method TWEAK(--> Nil) {
        @!resources = @!resources.flatmap(*.flat);
    }

    method auth { with $!auth // $!author // $!authority { .Str } else { Nil } }
    method ver  { with $!ver // $!version { $!ver ~~ Version ?? $_ !! $!ver = Version.new($_ // 0) } }
    method api  { with $!api { $!api ~~ Version ?? $_ !! $!api = Version.new($_ // 0) } }
    method hash {
        my %normalized = %(
            :$!meta-version,
            :$!name,
            :$.auth,
            :$.ver,
            :$.api,
            :$!description,
            :$!depends,
            :$!build-depends,
            :$!test-depends,
            :%!provides,
            :%!files,
            :@!resources,
            :$!license,
            :%!support,
            :$!source-url,
            :$.builder,
        );

        # Add non-spec keys back into the has output ( will do this properly when refactoring Distribution )
        %normalized{$_} //= $!meta{$_} for $!meta.hash.keys;

        %normalized<builder>:delete unless %normalized<builder>;
        %normalized<source-url>:delete unless %normalized<source-url>;

        return %normalized;
    }

    # make matching dependency names against a dist easier
    # when sorting the install order from the meta hash
    method depends-specs       {
        my $deps := $.depends ~~ Hash
            ?? $.depends<runtime build>.grep(*.defined).grep(*.<requires>).map(*.<requires>).map(*.Slip)
            !! $.depends;

        $deps.grep(*.defined).map({ Zef::Distribution::DependencySpecification.new(system-collapse($_)) }).grep(*.name);
    }
    method build-depends-specs {
        gather {
            for $.build-depends.grep(*.defined) {
                with Zef::Distribution::DependencySpecification.new(system-collapse($_)) {
                    take $_ if $_.name;
                }
            }
        }
    }
    method test-depends-specs  {
        gather for $.test-depends.grep(*.defined) {
            with Zef::Distribution::DependencySpecification.new(system-collapse($_)) {
                take $_ if $_.name;
            }
        }
    }

    # make locating a module that is part of a distribution (ex. URI::Escape of URI) easier.
    # it doesn't need to be a hash mapping as its just for matching
    has @!provides-specs;
    method provides-specs {
        @!provides-specs := +@!provides-specs ?? @!provides-specs !! @(self.hash<provides>).map({
            # if $spec.name is not defined then .key (the module name of the current provides)
            # is not a valid module name (according to Zef::Identity grammar anyway). I ran into
            # this problem with `NativeCall::Errno` where one of the provides was: `X:NativeCall::Errorno`
            # The single colon cannot just be fixed to DWIM because that could just as easily denote
            # an identity part (identity parts are separated by a *single* colon; double colon is left alone)
            my $spec = Zef::Distribution::DependencySpecification.new(self!long-name(.key));
            next unless defined($spec.name);
            $spec;
        }).grep(*.defined).Slip;
    }

    method provides-spec-matcher($spec, :$strict) { self.provides-specs.first({ ?$_.spec-matcher($spec, :$strict) }) }

    proto method contains-spec(|) {*}
    multi method contains-spec(Str $spec, |c)
        { samewith( Zef::Distribution::DependencySpecification.new($spec, |c) ) }
    multi method contains-spec(Zef::Distribution::DependencySpecification $spec, Bool :$strict = True)
        { so self.spec-matcher($spec, :$strict) || self.provides-spec-matcher($spec, :$strict)  }

    method Str {
        return self!long-name($!name);
    }

    method !long-name($name!) {
        return sprintf '%s:ver<%s>:auth<%s>:api<%s>',
            $name,
            (self.ver  // ''),
            (self.auth // '').trans(['<', '>'] => ['\<', '\>']),
            (self.api  // ''),
        ;
    }

    method id() {
        use nqp;
        return nqp::sha1(self.Str);
    }

    method WHICH(Zef::Distribution:D:) { "{self.^name}|{self.Str()}" }

    # For now we will use $dist.compat in spots where we pass to rakudo and there
    # are Distribution constraints (install and uninstall?). This provides backwards compatibility
    # until a more robust solution is worked out
    method compat {
        (::("Distribution::Hash").new(self.?meta || $.hash, :prefix(self.?IO // $*CWD)) but role {
            method name { self.meta<name> }
            method ver  { self.meta<ver> // self.meta<version> }
            method auth { self.meta<auth> }
        });
    }

    method meta { $.hash }
    method content($name-path) { self.compat.content($name-path) }
}
