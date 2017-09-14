class Zef::Identity {
    has $.name;
    has $.version;
    has $.auth;
    has $.api;

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
        token TOP {
            <name>
            [
            || [ <auth>    [[<version>  <api>? ] || [ <api> <version>?]?]?   ]
            || [ <version> [[<auth> <api>? ]     || [ <api> <auth>? ]?]?     ]
            || [ <api>     [[<auth> <version>? ] || [ <version> <auth>? ]?]? ]
            ]?
        }

        token name    { <.token>+ }

        proto token version {*};
        token version:sym(":ver(v") { <.sym> $<value>=[<.token>*?] ")"  }
        token version:sym(":ver('") { <.sym> $<value>=[<.token>*?] "')" }
        token version:sym(':ver("') { <.sym> $<value>=[<.token>*?] '")' }
        token version:sym(":ver<")  { <.sym> $<value>=[<.token>*?] '>'  }
        token version:sym(":version(v") { <.sym> $<value>=[<.token>*?] ")"  }
        token version:sym(":version('") { <.sym> $<value>=[<.token>*?] "')" }
        token version:sym(':version("') { <.sym> $<value>=[<.token>*?] '")' }
        token version:sym(":version<")  { <.sym> $<value>=[<.token>*?] '>'  }

        proto token api {*};
        token api:sym(":api(v") { <.sym> $<value>=[<.token>*?] ")"  }
        token api:sym(":api('") { <.sym> $<value>=[<.token>*?] "')" }
        token api:sym(':api("') { <.sym> $<value>=[<.token>*?] '")' }
        token api:sym(":api<")  { <.sym> $<value>=[<.token>*?] '>'  }

        proto token auth {*};
        token auth:sym(":auth('") { <.sym> $<value>=[$<cs>=<.token>*? ':'? $<owner>=<.token>*?] "')" }
        token auth:sym(':auth("') { <.sym> $<value>=[$<cs>=<.token>*? ':'? $<owner>=<.token>*?] '")' }
        token auth:sym(":auth<")  { <.sym> $<value>=[$<cs>=<.token>*? ':'? $<owner>=<.token>*?] '>'  }

        token token      { <-restricted +name-sep> }
        token restricted { < : > }
        token name-sep   { < :: > }
    }

    proto method new(|) {*}
    multi method new(Str :$name!, :ver(:$version), :$auth, :$api) {
        self.bless(:$name, :$version, :$auth, :$api);
    }
    multi method new(Str $id) {
        state %id-cache;
        %id-cache{$id} := %id-cache{$id}:exists ?? %id-cache{$id} !! do {
            if $id !~~ /':ver' | ':auth' | ':api'/ and URN.parse($id) -> $urn {
                self.bless(
                    name    => ~($urn<name>.subst('--','::') // ''),
                    version => ~($urn<version>               // ''),
                    auth    => ~($urn<auth>                  // ''),
                    api     => ~($urn<api>                   // ''),
                );
            }
            elsif REQUIRE.parse($id) -> $ident {
                self.bless(
                    name    => ~($ident<name>           // ''),
                    version => ~($ident<version><value> // ''),
                    auth    => ~($ident<auth><value>    // ''),
                    api     => ~($ident<api><value>     // ''),
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
