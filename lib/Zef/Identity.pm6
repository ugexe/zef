class Zef::Identity {
    has $.name;
    has $.version;
    has $.auth;
    has $.api;
    has $.from;

    method CALL-ME($id) { try self.new(|$id) }

    my grammar URN {
        token TOP { <auth> ':' <name> ':' <version> [':' <api>]? }

        token name { <token>+ }

        token auth    { <cs> ':' <owner> }
        token cs      { <.token>+ }
        token owner   { <.token>+ }
        token version { <.token>+ }
        token api     { <.token>+ }

        token token      { <-restricted> }
        token restricted { < : > }
    }

    my grammar REQUIRE {
        regex TOP { ^^ <name> [':' <key> <value>]* $$ }

        regex name  { <-restricted +name-sep>+ }
        token key   { <-restricted>+ }
        token value { '<' ~ '>'  [<( [[ <!before \>|\\> . ]+]* % ['\\' . ] )>] }

        token restricted { [':' | '<' | '>' | '(' | ')'] }
        token name-sep   { < :: > }
    }

    my class REQUIRE::Actions {
        method TOP($/) { make %('name'=> $/<name>.made, %($/<key> Z=> $/<value>>>.ast)) if $/ }

        method name($/)  { make $/.Str }
        method key($/)   { my $str = make $/.Str; ($str eq 'ver') ?? 'version' !! $str }
        method value($/) { make $/.Str }
    }

    proto method new(|) {*}
    multi method new(Str :$name!, :ver(:$version), :$auth, :$api, :$from) {
        self.bless(:$name, :$version, :$auth, :$api, :$from);
    }

    multi method new(Str $id) {
        state %id-cache;
        %id-cache{$id} := %id-cache{$id}:exists ?? %id-cache{$id} !! do {
            if $id.starts-with('.' | '/') {
                self.bless(
                    name    => $id,
                    version => '',
                    auth    => '',
                    api     => '',
                    from    => '',
                );
            }
            elsif $id !~~ /':ver' | ':auth' | ':api' | ':from'/ and URN.parse($id) -> $urn {
                self.bless(
                    name    => ~($urn<name>.subst('--','::') // ''),
                    version => ~($urn<version>               // ''),
                    auth    => ~($urn<auth>                  // ''),
                    api     => ~($urn<api>                   // ''),
                    from    => ~($urn<from>                  // 'Perl6'),
                );
            }
            elsif REQUIRE.parse($id, :actions(REQUIRE::Actions.new)).ast -> $ident {
                self.bless(
                    name    => ~($ident<name>    // ''),
                    version => ~($ident<ver>     // ''),
                    auth    => ~($ident<auth>    // ''),
                    api     => ~($ident<api>     // ''),
                    from    => ~($ident<from>    || 'Perl6'),
                );
            }
        }
    }

    # cpan:UGEXE:Acme--Foo:1.0 # Module/Distrution Acme::Foo
    # cpan:UGEXE:Acme-Foo:1.0  # Module/Distrution Acme-Foo
    method urn {
        return "{$!auth}:{$!name.subst('::', '--')}:{$!version}{$!api ?? ':$!api' !! ''}"
            if ($!auth.?chars && $!name.?chars && $!version.?chars);
    }

    # Acme::Foo::SomeModule:auth<cpan:ugexe>:ver('1.0')
    method identity {
        $!name
            ~ (($!version // '' ) ne ('*' | '') ?? ":ver<"  ~ ($!version.starts-with('v') ?? $!version.substr(1) !! $!version) ~ ">" !! '')
            ~ (($!auth    // '' ) ne ('*' | '') ?? ":auth<" ~ $!auth     ~ ">" !! '')
            ~ (($!api     // '' ) ne ('*' | '') ?? ":api<"  ~ $!api      ~ ">" !! '');
    }

    method hash {
        my %hash;
        %hash<name> = $!name    // '';
        %hash<ver>  = $!version // '';
        %hash<auth> = $!auth    // '';
        %hash<api>  = $!api     // '';
        %hash<from> = $!from    // '';
        %hash;
    }
}

sub str2identity($str) is export {
    # todo: when $str is a path
    Zef::Identity($str).?identity // $str;
}

sub identity2hash($identity) is export {
    Zef::Identity($identity).?hash;
}

sub hash2identity($hash) is export {
    Zef::Identity($hash).?identity;
}
