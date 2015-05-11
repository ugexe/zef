use Zef::Grammars::HTTP::RFC3986; # uri
use Zef::Grammars::HTTP::RFC7230; # http

# These should probably be placed outside the Zef::Grammars namespace 
# after the structure is fleshed out further.

class Zef::Grammars::URI {
    has $.grammar;
    has $.url;
    has $.scheme;
    has $.user-info;
    has $.host;
    has $.port;
    has $.query;
    has $.fragment;
    has $.location;

    submethod BUILD(:$!url) {
        $!grammar = Zef::Grammars::HTTP::RFC3986.parse($!url) if $!url;

        if $!grammar {
            $!scheme    = ~($!grammar.<URI-reference>.<URI>.<scheme>                           //  '');
            $!host      = ~($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<host>     //  '');
            $!port      =  ($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<port>     // Int).Int;
            $!user-info = ~($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<userinfo> //  '');
        }
    }

    method Str {
        return $!grammar.Str;
    }
}

class Zef::Grammars::HTTPResponse {
    has $.grammar;
    has $.message;
    has $.status-code;
    has $.status-message;
    has $.body;
    has %.header;

    submethod BUILD(:$!message) {
        $!grammar = Zef::Grammars::HTTP::RFC7230.parse($!message) if $!message;

        if $!grammar {
            $!status-code    =  ($!grammar.<HTTP-message>.<start-line>.<status-line>.<status-code>   // Int).Int;
            $!status-message = ~($!grammar.<HTTP-message>.<start-line>.<status-line>.<reason-phrase> //  '');
            $!body           = ~($!grammar.<HTTP-message>.<message-body>                             //  '');

            for $!grammar.<HTTP-message>.<header-field>.list -> $field {
                %!header.{~$field.<name>} = ~$field.<value>;
            }
        }
    }

    method Str {
        return $!grammar.Str;
    }
}

