class Zef::Distribution::DependencySpecification {
    has Str $.name;
    has Str $.version-matcher;
    has Str $.auth-matcher;
    has Str $.api-matcher;

    method new($identity is copy) {
        my $version-matcher = ~($identity.subst-mutate(/":ver"  ["<" | "("] (.*?) [">" | ")"]/, "")[0] // "*");
        my $auth-matcher    = ~($identity.subst-mutate(/":auth" ["<" | "("] (.*?) [">" | ")"]/, "")[0] // "");
        my $api-matcher     = ~($identity.subst-mutate(/":api"  ["<" | "("] (.*?) [">" | ")"]/, "")[0] // "");
        self.bless(:name($identity), :$version-matcher, :$auth-matcher, :$api-matcher);
    }

    method ACCEPTS(Distribution $dist) {
        return False unless $dist.name eq $!name;
        if $!version-matcher.chars {
            return False unless Version.new($dist.ver) ~~ Version.new($!version-matcher);
        }
        if $!auth-matcher.chars {
            return False unless $dist.auth eq $!auth-matcher;
        }
        if $!api-matcher.chars {
            return False unless $dist.api eq $!api-matcher;
        }
        return True;
    }

    method Str() {
        return "{$.name}:ver<{$.version-matcher  // ''}>:auth<{$.auth-matcher // ''}>:api<{$.api-matcher // ''}>";
    }
}
