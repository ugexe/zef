# Hypertext Transfer Protocol (HTTP/1.1): Caching

role Zef::Net::HTTP::Grammar::RFC7234 {
    token Age           { <.delta-seconds> }
    token Cache-Control { [[<.OWS> <cache-directive>]*] *%% ',' }

    # Added `|| (.*?)` to make it easier to handle invalid expires contents as expired (as the spec requires)
    # i.e. -1 or 0 should be treated as an expired value and not invalidate the header
    token Expires       { <.HTTP-date> || <.token> }

    # token HTTP-date 7231

    # token OWS 7230

    token Pragma           { <pragma-value> +%% ','         }
    token pragma-value     { [[<.OWS> <pragma-directive>]*] }

    token warning          { <warning-value> +%% ','      }
    token warning-value    { [[<.OWS> <warning-string>]*] }

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

    token warning-string { <.warn-code> <.SP> <.warn-agent> <.SP> <.warn-text> [<.SP> <.warn-date>]? }
}

