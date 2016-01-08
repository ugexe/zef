# punnable so we can use it on `provides` instead of using a new Distribution
# as those are not actually Distributions, while providing these methods to
# actual Distributions
class Zef::Distribution::DependencySpecification {
    has $.id;
    # todo: handle wildcard/+ (like "1.2.3+", "1.2.*", "*:ugexe", "github:*")

    submethod new($id) { self.bless(:$id) }

    method !id { $ = self.?identity // $.id }

    method identity-parts {
        state %ids;
        %ids{self!id} //= IDENTITY2HASH(self!id);
    }

    method name {
        my $name = callsame() || self.identity-parts<name>;
    }

    method version-matcher {
        my $ver = self.identity-parts<ver>;
    }

    method auth-matcher {
        my $auth = self.identity-parts<auth>;
    }

    method api-matcher {
        my $api = self.identity-parts<api>;
    }


    method spec-matcher($spec) {
        return False unless $spec.name eq self.name;
        if $.version-matcher.chars {
            return False unless Version.new($spec.version-matcher) ~~ Version.new($.version-matcher);
        }
        if $.auth-matcher.chars {
            return False unless $spec.auth-matcher eq $.auth-matcher;
        }
        if $.api-matcher.chars {
            return False unless Version.new($spec.api-matcher) ~~ Version.new($.api-matcher);
        }
        return True;
    }
}

sub IDENTITY2HASH($identity is copy) is export {
    my $ver  = ~($identity.subst-mutate(/":ver"  ["<" | "("] (.*?) [">" | ")"]/, "")[0] // "*");
    my $auth = ~($identity.subst-mutate(/":auth" ["<" | "("] (.*?) [">" | ")"]/, "")[0] // "");
    my $api  = ~($identity.subst-mutate(/":api"  ["<" | "("] (.*?) [">" | ")"]/, "")[0] // "*");
    my $name = $identity;
    return %(:$name, :$ver, :$auth, :$api);
}
