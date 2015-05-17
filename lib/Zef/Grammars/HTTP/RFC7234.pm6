use v6;
# Hypertext Transfer Protocol (HTTP/1.1): Caching

use Zef::Grammars::HTTP::RFC7235;

role Zef::Grammars::HTTP::RFC7234::Core is Zef::Grammars::HTTP::RFC7235 {
    token Age           { <.delta-seconds> }
    token Cache-Control { [',' <.OWS>]* <.cache-directive> [<.OWS> ',' [<.OWS> <.cache-directive>]?]* }

    # Added `|| (.*?)` to make it easier to handle invalid expires contents as expired (as the spec requires)
    # i.e. -1 or 0 should be treated as an expired value and not invalidate the header
    token Expires       { <.HTTP-date> || <.token> }

    # token HTTP-date 7231

    # token OWS 7230

    token Pragma           { [',' <.OWS>]* <.pragma-directive> [<.OWS> ',' [<.OWS> <.pragma-directive>]?]* }
    token warning          { [',' <.OWS>]* <.warning-value> [<.OWS> ',' [<.OWS> <.warning-value>]?]* }
    token cache-directive  { <.token> ['=' [<.token> || <.quoted-string>]]? }
    token delta-second     { <.DIGIT>+ }
    token extension-pragma { <.token> ['=' [<.token> || <.quoted-string>]]? }

    # token field-name 7230

    # token port 7230

    token pragma-directive { 'no-cache' || <.extension-pragma> }

    # token pseydonym 7230

    # token quoted-string 7230

    # token token 7230

    # token uri-host 7230

    token warn-agent { 
        || [<.uri-host> [':' <.port>]?]
        || <.pseydonym>
    }

    token warn-code { <.DIGIT> ** 3 }

    token warn-date { <.DQUOTE> <.HTTP-date> <.DQUOTE> }

    token warn-text { <.quoted-string> }

    token warning-value { <.warn-code> <.SP> <.warn-agent> <.SP> <.warn-text> [<.SP> <.warn-date>]? }
}


grammar Zef::Grammars::HTTP::RFC7234 is Zef::Grammars::HTTP::RFC7234::Core {
    # todo
    token TOP {
        <Expires> 
    }
}
