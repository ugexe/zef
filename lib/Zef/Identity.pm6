class Zef::Identity {
    has $.name;
    has $.version;
    has $.auth;
    has $.api;
    has $.from;

    method CALL-ME($id) {
        once { note 'Zef::Identity(...) is deprecated. Use Zef::Identity.new(...) instead' }
        try self.new(|$id)
    }

    my grammar REQUIRE {
        regex TOP { ^^ <name> [':' <key> <value>]* $$ }

        regex name  { <-restricted +name-sep>+ }
        token key   { <-restricted>+ }
        regex value { '<' ~ '>' [<( [[ <!before \>|\<|\\> . ]+?]* %% ['\\' . ]+ )>] }

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
        if $id.starts-with('.' | '/') {
            self.bless(
                name    => $id,
                version => '',
                auth    => '',
                api     => '',
                from    => '',
            );
        }
        elsif REQUIRE.parse($id, :actions(REQUIRE::Actions)).ast -> $ident {
            self.bless(
                name    => ~($ident<name>    // ''),
                version => ~($ident<ver version>.first(*.defined) // ''),
                auth    => ~($ident<auth>    // '').trans(['\<', '\>'] => ['<', '>']),
                api     => ~($ident<api>     // ''),
                from    => ~($ident<from>    || 'Perl6'),
            );
        }
    }

    # Acme::Foo::SomeModule:auth<cpan:ugexe>:ver('1.0')
    method identity {
        $!name
            ~ (($!version // '' ) ne ('*' | '')     ?? ":ver<"  ~ $!version ~ ">" !! '')
            ~ (($!auth    // '' ) ne ('*' | '')     ?? ":auth<" ~ $!auth    ~ ">" !! '')
            ~ (($!api     // '' ) ne ('*' | '')     ?? ":api<"  ~ $!api     ~ ">" !! '')
            ~ (($!from    // '' ) ne ('Perl6' | '') ?? ":from<" ~ $!from    ~ ">" !! '');
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
    Zef::Identity.new($str).?identity // $str;
}

sub identity2hash($identity) is export {
    Zef::Identity.new($identity).?hash;
}

sub hash2identity($hash) is export {
    Zef::Identity.new(|$hash).?identity;
}
