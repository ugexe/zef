class Zef::Identity {
    has $.name;
    has $.version;
    has $.auth;
    has $.api;

    method CALL-ME($id) { try self.new($id) }

    my grammar Distribution {
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

    my grammar Module {
        token TOP {
            <name>
            [
            || [ <auth> [[<ver>  <api>? ] || [ <api> <ver>?  ]?]? ]
            || [ <ver>  [[<auth> <api>? ] || [ <api> <auth>? ]?]? ]
            || [ <api>  [[<auth> <ver>? ] || [ <ver> <auth>? ]?]? ]
            ]?
        }

        token name    { <.token>+ }

        proto token ver {*};
        token ver:sym(":ver(v") { <.sym> <.token>+? ")"  }
        token ver:sym(":ver('") { <.sym> <.token>+? "')" }
        token ver:sym(':ver("') { <.sym> <.token>+? '")' }
        token ver:sym(":ver<")  { <.sym> <.token>+? '>'  }

        proto token api {*};
        token api:sym(":api(v") { <.sym> <.token>+? ")"  }
        token api:sym(":api('") { <.sym> <.token>+? "')" }
        token api:sym(':api("') { <.sym> <.token>+? '")' }
        token api:sym(":api<")  { <.sym> <.token>+? '>'  }

        proto token auth {*};
        token auth:sym(":auth('") { <.sym> $<cs>=<.token>*? ':'? $<owner>=<.token>+? "')" }
        token auth:sym(':auth("') { <.sym> $<cs>=<.token>*? ':'? $<owner>=<.token>+? '")' }
        token auth:sym(":auth<")  { <.sym> $<cs>=<.token>*? ':'? $<owner>=<.token>+? '>'  }

        token token      { <-restricted +name-sep> }
        token restricted { < : > }
        token name-sep   { < :: > }
    }

    # todo: sanitize/clean bad auths
    method new($id) {
        if Distribution.parse($id) -> $urn {
            return self.bless(
                name    => ~($urn<name>    // ''),
                version => ~($urn<version> // ''),
                auth    => ~($urn<auth>    // ''),
                api     => ~($urn<api>     // ''),
                type    => 'dist',
            );
        }
        elsif Module.parse($id) -> $ident {
            return self.bless(
                name    => ~($ident<name>    // ''),
                version => ~($ident<version> // ''),
                auth    => ~($ident<auth>    // ''),
                api     => ~($ident<api>     // ''),
                type    => 'module',
            );
        }
    }

    # cpan:UGEXE:Acme-Foo:1.0
    method dist-str   {
        return "{$!auth}:{$!name.subst('::', '-')}:{$!version}{$!api ?? ':$!api' !! ''}"
            if ($!auth.?chars && $!name.?chars && $!version.?chars);
    }

    # Acme::Foo::SomeModule:auth<cpan:ugexe>:ver('1.0')
    method module-str {
        $!name
            ~ (($!version // '' ) ne ('*' | '') ?? ":ver('"  ~ $!version  ~ "')" !! '')
            ~ (($!auth    // '' ) ne ('*' | '') ?? ":auth('" ~ $!auth     ~ "')" !! '')
            ~ (($!api     // '' ) ne ('*' | '') ?? ":api('"  ~ $!api      ~ "')" !! '');
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
