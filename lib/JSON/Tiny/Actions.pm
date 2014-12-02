class JSON::Tiny::Actions;

method TOP($/) {
    make $/.values.[0].ast;
};
method object($/) {
    make $<pairlist>.ast.hash;
}

method pairlist($/) {
    make $<pair>>>.ast.flat;
}

method pair($/) {
    make $<string>.ast => $<value>.ast;
}

method array($/) {
    make $<arraylist>.ast;
}

method arraylist($/) {
    make [$<value>>>.ast];
}

method string($/) {
    make $0.elems == 1
        ?? ($0[0].<str> || $0[0].<str_escape>).ast
        !! join '', $0.list.map({ (.<str> || .<str_escape>).ast });
}
method value:sym<number>($/) { make +$/.Str }
method value:sym<string>($/) { make $<string>.ast }
method value:sym<true>($/)   { make Bool::True  }
method value:sym<false>($/)  { make Bool::False }
method value:sym<null>($/)   { make Any }
method value:sym<object>($/) { make $<object>.ast }
method value:sym<array>($/)  { make $<array>.ast }

method str($/)               { make ~$/ }

method str_escape($/) {
    if $<xdigit> {
        make chr(EVAL "0x" ~ $<xdigit>.join);
    } else {
        my %h = '\\' => "\\",
                '/'  => "/",
                'b'  => "\b",
                'n'  => "\n",
                't'  => "\t",
                'f'  => "\f",
                'r'  => "\r",
                '"'  => "\"";
        make %h{~$/};
    }
}


# vim: ft=perl6
