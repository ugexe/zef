use Zef;
use Zef::Identity;

role DependencySpecification {
    method name(--> Str) { ... }
    method identity(--> Str) { ... }
    method spec-matcher($spec --> Bool:D) { ... }
}

class Zef::Distribution::DependencySpecification::Any does DependencySpecification {
    has @.specs;
    method name { "any({@.specs.map(*.name).join(', ')})" }
    method identity { "any({@.specs.map(*.identity).join(',')})" }
    method spec-matcher($spec --> Bool:D) {
        return so @!specs.first(*.spec-matcher($spec));
    }
}

class Zef::Distribution::DependencySpecification does DependencySpecification {
    has $!ident;
    has $.spec;

    submethod TWEAK(:$!spec, :$!ident) { }
    multi submethod new(Zef::Identity $ident) { self.bless(:$ident) }
    multi submethod new(Str $spec) { self.bless(:$spec) }
    multi submethod new(Hash $spec) { self.bless(:$spec) }
    multi submethod new(Hash $spec where {$_.keys == 1 and $_.keys[0] eq 'any'}) {
        Zef::Distribution::DependencySpecification::Any.new: :specs(
            $spec.values[0].map: {self.new($_)}
        )
    }
    multi submethod new($spec) {
        die "Invalid dependency specification: $spec.gist()";
    }

    method identity {
        my $hash = %(:name($.name), :ver($.version-matcher), :auth($.auth-matcher), :api($.api-matcher), :from($.from-matcher));
        my $identity = hash2identity( $hash );
        $identity;
    }

    method clone(|) { $!ident = Nil; nextsame(); }

    method spec-parts(Zef::Distribution::DependencySpecification:_: $spec = self!spec) {
        # Need to find a way to break this cache when a distribution gets cloned with a different version
        $!ident //= Zef::Identity.new(|$spec);
        $!ident.?hash;
    }

    method name            { self.spec-parts<name> }

    method ver             { self.spec-parts<ver> }

    method version-matcher { self.spec-parts<ver>  // '*' }

    method auth-matcher    { self.spec-parts<auth> // ''  }

    method api-matcher     { self.spec-parts<api>  // '*' }

    method from-matcher     { self.spec-parts<from> // '' }

    method !spec { $.spec || self.Str }

    multi method spec-matcher(Zef::Distribution::DependencySpecification::Any $spec, Bool :$strict = True) {
        self.spec-matcher(any($spec.specs), :$strict)
    }

    multi method spec-matcher($spec, Bool :$strict = True) {
        return False unless $spec.name.?chars && self.name.?chars;
        if $strict {
            return False unless $spec.name eq self.name;
        }
        else {
            my $name = $spec.name;
            return False unless self.name ~~ /[:i $name]/;
        }

        if $spec.auth-matcher.chars {
            return False unless $.auth-matcher.chars && $spec.auth-matcher eq $.auth-matcher;
        }

        if $spec.version-matcher.chars && $spec.version-matcher ne '*' && $.version-matcher ne '*' {
            my $spec-version = Version.new($spec.version-matcher);
            my $self-version = Version.new($.version-matcher);
            return False unless self!version-matcher(:$spec-version, :$self-version);
        }

        if $spec.api-matcher.chars && $spec.api-matcher ne '*' && $.api-matcher ne '*' {
            my $spec-version = Version.new($spec.api-matcher);
            my $self-version = Version.new($.api-matcher);
            return False unless self!version-matcher(:$spec-version, :$self-version);
        }

        return True;
    }

    method !version-matcher(Version :$self-version is copy, Version :$spec-version is copy) {
        # Normalize the parts between version so that Version ~~ Version works in the way we need
        # Example: for `0.1 ~~ 0.1.1` we want `0.1.0` ~~ `0.1.1`
        my $self-add-parts = $spec-version.parts.elems - $self-version.parts.elems;
        $self-version = Version.new( (|$self-version.parts, |(0 xx $self-add-parts), ("+" if $self-version.plus)).join('.') )
            if $self-add-parts > 0;
        my $spec-add-parts = $self-version.parts.elems - $spec-version.parts.elems;
        $spec-version = Version.new( (|$spec-version.parts, |(0 xx $spec-add-parts), ("+" if $spec-version.plus)).join('.') )
            if $spec-add-parts;

        return $self-version ~~ $spec-version;
    }
}
