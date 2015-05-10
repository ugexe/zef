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

    submethod BUILD(:$!url) {
        $!grammar = Zef::Grammars::HTTP::RFC3986.parse($!url) if $!url;

        if $!grammar {
            $!scheme = ($!grammar.<URI-reference>.<URI>.<scheme>.Str                   // Str).Str;
            $!host   = ($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<host> // Str).Str;
            $!port   = ($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<port> // Int).Int;
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
    has $.header;
    has $.body;

    submethod BUILD(:$!message) {
        $!grammar = Zef::Grammars::HTTP::RFC7230.parse($!message) if $!message;

        if $!grammar {
            $!status-code    = ($!grammar.<HTTP-message>.<start-line>.<status-line>.<status-code>.Int   // Int).Int;
            $!status-message = ($!grammar.<HTTP-message>.<start-line>.<status-line>.<reason-phrase>.Str // Str).Str;
            $!header         = ($!grammar.<HTTP-message>.<header-field>.Str                             // Str).Str;
            $!body           = ($!grammar.<HTTP-message>.<message-body>.Str                             // Str).Str;
        }
    }

    method Str {
        return $!grammar.Str;
    }
}

