use v6;
grammar JSON::Tiny::Grammar;

token TOP       { ^ \s* [ <object> | <array> ] \s* $ }
rule object     { '{' ~ '}' <pairlist>     }
rule pairlist   { <?> <pair> * % \,             }
rule pair       { <?> <string> ':' <value>     }
rule array      { '[' ~ ']' <arraylist>    }
rule arraylist  { <?> <value>* % [ \, ]        }

proto token value {*};
token value:sym<number> {
    '-'?
    [ 0 | <[1..9]> <[0..9]>* ]
    [ \. <[0..9]>+ ]?
    [ <[eE]> [\+|\-]? <[0..9]>+ ]?
}
token value:sym<true>    { <sym>    };
token value:sym<false>   { <sym>    };
token value:sym<null>    { <sym>    };
token value:sym<object>  { <object> };
token value:sym<array>   { <array>  };
token value:sym<string>  { <string> }

token string {
    \" ~ \" ( <str> | \\ <str_escape> )*
}

token str {
    <-["\\\t\n]>+
}

token str_escape {
    <["\\/bfnrt]> | u <xdigit>**4
}

# vim: ft=perl6
