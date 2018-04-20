use Zef::Identity;

class Zef::Distribution::DependencySpecification {
    has $!ident;
    has $.spec;
    # todo: handle wildcard/+ (like "1.2.3+", "1.2.*", "*:ugexe", "github:*")

    submethod new($spec) { self.bless(:$spec) }

    method identity {
        my $hash = %(:name($.name), :ver($.version-matcher), :auth($.auth-matcher), :api($.api-matcher), :from($.from-matcher));
        my $identity = hash2identity( $hash );
        $identity;
    }

    method clone(|) { $!ident = Nil; nextsame(); }

    method spec-parts(Zef::Distribution::DependencySpecification:_: $spec = self!spec) {
        # Need to find a way to break this cache when a distribution gets cloned with a different version
        $!ident //= Zef::Identity($spec);
        $!ident.?hash;
    }

    method name            { self.spec-parts<name> }

    method version-matcher { self.spec-parts<ver>  // '*' }

    method auth-matcher    { self.spec-parts<auth> // ''  }

    method api-matcher     { self.spec-parts<api>  // '*' }

    method from-matcher     { self.spec-parts<from> // '' }

    method !spec { $.spec || self.Str }

    method spec-matcher($spec, Bool :$strict = True) {
        return False unless $spec.name.?chars && self.name.?chars;
        if $strict {
            return False unless $spec.name.lc eq self.name.lc;
        }
        else {
            my $name = $spec.name;
            return False unless self.name ~~ /[:i $name]/;
        }

        if $spec.version-matcher.chars && $spec.version-matcher ne '*' {
            my $spec-version = Version.new($spec.version-matcher);
            my $self-version = Version.new($.version-matcher);

            # Normalize the parts between version so that Version ~~ Version works in the way we need
            # Example: for `0.1 ~~ 0.1.1` we want `0.1.0` ~~ `0.1.1`
            my $self-add-parts = $spec-version.parts.elems - $self-version.parts.elems;
            $self-version = Version.new( (|$self-version.parts, |(0 xx $self-add-parts), ("+" if $self-version.plus)).join('.') )
                if $self-add-parts > 0;
            my $spec-add-parts = $self-version.parts.elems - $spec-version.parts.elems;
            $spec-version = Version.new( (|$spec-version.parts, |(0 xx $spec-add-parts), ("+" if $spec-version.plus)).join('.') )
                if $spec-add-parts;

            return False unless ?$.version-matcher
                && $.version-matcher ne '*'
                && $self-version ~~ $spec-version;
        }
        if $spec.auth-matcher.chars {
            return False unless $.auth-matcher.chars && $spec.auth-matcher eq $.auth-matcher;
        }
        if $spec.api-matcher.chars && $.api-matcher ne '*' {
            return False unless Version.new($spec.api-matcher) ~~ Version.new($.api-matcher);
        }
        return True;
    }
}
