use Zef::Identity;

class Zef::Distribution::DependencySpecification {
    has $!ident;
    has $.spec;
    # todo: handle wildcard/+ (like "1.2.3+", "1.2.*", "*:ugexe", "github:*")

    submethod new($spec) { self.bless(:$spec) }

    method spec { $ = self.?identity // $!spec }

    method spec-parts(Zef::Distribution::DependencySpecification:_: $spec?) {
        $!ident //= Zef::Identity($spec // self.spec);
        $!ident.?hash;
    }

    method name { $ = callsame() // self.spec-parts<name> }

    method version-matcher { $ = self.spec-parts<ver>  }

    method auth-matcher    { $ = self.spec-parts<auth> }

    method api-matcher     { $ = self.spec-parts<api>  }


    method spec-matcher($spec) {
        return False unless $spec.name eq self.name;
        if $spec.version-matcher.chars && $spec.version-matcher ne '*' {
            return False unless ?$.version-matcher
                && $.version-matcher ne '*'
                && Version.new($spec.version-matcher) ~~ Version.new($.version-matcher);
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
