# punnable so we can use it on `provides` instead of using a new Distribution
# as those are not actually Distributions, while providing these methods to
# actual Distributions
class Zef::Distribution::DependencySpecification {
    has $.spec;
    # todo: handle wildcard/+ (like "1.2.3+", "1.2.*", "*:ugexe", "github:*")

    submethod new($spec) { self.bless(:$spec) }

    method spec { $ = self.?identity // $!spec }

    method spec-parts(Zef::Distribution::DependencySpecification:_: $spec?) {
        IDENTITY2HASH($spec // self.spec // return {});
    }

    method name {
        my $name = callsame() || self.spec-parts<name>;
    }

    method version-matcher {
        my $ver = self.spec-parts<ver>;
    }

    method auth-matcher {
        my $auth = self.spec-parts<auth>;
    }

    method api-matcher {
        my $api = self.spec-parts<api>;
    }


    method spec-matcher($spec) {
        return False unless $spec.name eq self.name;

        if $spec.version-matcher.chars && $spec.version-matcher ne '*' {
            return False unless $.version-matcher ne '*' && Version.new($spec.version-matcher) ~~ Version.new($.version-matcher);
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



# xxx: extremely crude. only meant to create an identity that `use` will understand to test if something is installed
sub IDENTITY2HASH($identity is copy) is export {
    state %ids;
    %ids{$identity} //= do {
        my $ver  = ~($identity.subst-mutate(/":ver"  ["<" || ["(" $<q>=["'" | '"']]] (.*?) [[$<q> ")"] || ">"]/, "")[0] // "*");
        my $api  = ~($identity.subst-mutate(/":api"  ["<" || ["(" $<q>=["'" | '"']]] (.*?) [[$<q> ")"] || ">"]/, "")[0] // "*");
        my $auth = ~($identity.subst-mutate(/":auth" ["<" || ["(" $<q>=["'" | '"']]] (.*)  [[$<q> ")"] || ">"]/, "")[0] // "");
        my $name = $identity;
        %(:$name, :$ver, :$auth, :$api);
    }
}

sub HASH2IDENTITY(%hash) is export {
    %hash<name>
        ~ ((%hash<ver>  // '' ) ne ('*' | '') ?? ":ver('"  ~ %hash<ver>  ~ "')" !! '')
        ~ ((%hash<auth> // '' ) ne ('*' | '') ?? ":auth('" ~ %hash<auth> ~ "')" !! '')
        ~ ((%hash<api>  // '' ) ne ('*' | '') ?? ":api('"  ~ %hash<api>  ~ "')" !! '');
}

sub URN2HASH($identity) is export {
    my $clean = $identity.subst('::', '  ', :g);
    my @parts = $clean.split(':', 4);
    my %hash;
    given +@parts {
        when 1 {
            %hash<name> = @parts[0];
        }
        when 2 {
            %hash<name> = @parts[0];
            %hash<ver>  = @parts[1];
        }
        when 3 {
            %hash<auth> = @parts[0];
            %hash<name> = @parts[1];
            %hash<ver>  = @parts[2];
        }
        when 4 {
            %hash<auth> = @parts[0,1].join(':');
            %hash<name> = @parts[2];
            %hash<ver>  = @parts[3];
        }
    }
    %hash<name> .= subst('  ', '-',  :g);
    %hash<name> .= subst('-',  '::', :g);

    %hash;
}

sub URN2IDENTITY($identity) is export {
    HASH2IDENTITY(URN2HASH($identity))
}

sub STR2IDENTITY($str) is export {
    $str ~~ / [':ver<' || ':ver('] || [':auth<' || ':auth('] || [':api<' || ':api('] /
        ?? $str !! URN2IDENTITY($str);
}
