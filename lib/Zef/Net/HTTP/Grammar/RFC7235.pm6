# Hypertext Transfer Protocol (HTTP/1.1): Authentication

role Zef::Net::HTTP::Grammar::RFC7235 {
    token Authorization       { <.credentials>                  }
    token Proxy-Authenticate  { [[<.OWS> <challenge>]*] *%% ',' }
    token Proxy-Authorization { <.credentials>                  }
    token WWW-Authenticate    { [[<.OWS> <challenge>]*] *%% ',' }

    token auth-param  { <.token> <.BWS> '=' <.BWS> [<.token> || <.quoted-string>] }
    token auth-scheme { <.token> }
    token challenge   { 
        <.auth-scheme>
        [ <.SP>+
            [
            || <.token68>
            || [[<OWS> <auth-param>]*] *%% ','
            ]
        ]?
    }


    token token68 { [<.ALPHA> || <.DIGIT> || < - . _ ~ + / >]+ '='* }
}
