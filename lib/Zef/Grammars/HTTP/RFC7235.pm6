use v6;
# Hypertext Transfer Protocol (HTTP/1.1): Authentication

use Zef::Grammars::HTTP::RFC3986;

role Zef::Grammars::HTTP::RFC7235::Core is Zef::Grammars::HTTP::RFC3986 {
    token Authorization { <.credentials> }

    token Proxy-Authenticate {
        [',' <.OWS>]* <.challenge> [<.OWS> ',' [<.OWS> <.challenge>]?]*
    }

    token Proxy-Authorization { <.credentials> }

    token WWW-Authenticate { 
        [',' <.OWS>]* <.challenge> [<.OWS> ',' [<.OWS> <.challenge>]?]*
    }

    token auth-param { <.token> <.BWS> '=' <.BWS> [<.token> || <.quoted-string>] }

    token auth-scheme { <.token> }

    token challenge { 
        <.auth-scheme>
        [
        <.SP>+
        [
        ||  <.token68>
        ||  [
            [',' || <.auth-param>]
            [<.OWS> ',' [<.OWS> <.auth-param>]?]*
            ]?
        ]
        ]?
    }


    token token68 { [<.ALPHA> || <.DIGIT> || '-' || '.' || '_' || '~' || '+' || '/' ]+ '='* }
}


grammar Zef::Grammars::HTTP::RFC7235 is Zef::Grammars::HTTP::RFC7235::Core {
    # todo
    token TOP {
        <Expires> 
    }
}
