# Hypertext Transfer Protocol (HTTP/1.1): Authentication

role Zef::Net::HTTP::Grammar::RFC7235 {
    token Authorization       { <.credentials> }

    token Proxy-Authenticate  { <proxy-authenticate-value> +%% ',' }
    token proxy-authenticate-value  { [[<.OWS> <challenge>]*]      }

    token Proxy-Authorization { <.credentials> }

    token WWW-Authenticate       { <www-authenticate-value> +%% ',' }
    token www-authenticate-value { [[<.OWS> <challenge>]*]          }

    token auth-param  { $<name>=<.token> <.BWS> '=' <.BWS> $<value>=[<.token> || <.quoted-string>] }
    token auth-scheme { <.token> }
    token challenge   { 
        <.auth-scheme>
        [ <.SP>+
            [
            || <.token68>
            || [[<OWS> <auth-param>]*] +%% ','
            ]
        ]?
    }
    token credentials { 
        <.auth-scheme>
        [ <.SP>+
            [
            || <.token68>
            || [[<OWS> <auth-param>]*] +%% ','
            ]
        ]?
    }


    token token68 { [<.ALPHA> || <.DIGIT> || < - . _ ~ + / >]+ '='* }
}
