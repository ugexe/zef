role Zef::Net::HTTP::Grammar::Extensions {
    token directive                 { <directive-name> [ "=" <directive-value> ]? }
    token directive-name            { <.token>                                    }
    token directive-value           { <.token> || <.quoted-string>                }

    # Header extensions
    # These are known headers that are not defined  in an RFC
    # (or in an RFC not implemented in these grammars yet)
    # The default field-value from RFC7230 does not detect
    # when to use the various parameter separation rules without
    # explicitly telling it, so explicitly tell it we shall.
    token known-header:sym<Alternate-Protocol> { <.sym> }
    token known-header:sym<Keep-Alive>         { <.sym> }
    token known-header:sym<P3P>                { <.sym> }
    token known-header:sym<Strict-Transport-Security> {<.sym> }
    token known-header:sym<X-Powered-By>       { <.sym> }
    token known-header:sym<X-Robots-Tag>       { <.sym> }
    token known-header:sym<X-UA-Compatible>    { <.sym> }
    token known-header:sym<X-XSS-Protection>   { <.sym> }
    token known-header:sym<Status> { <.sym> }

    token Status { <status-code> <.SP> <reason-phrase> }


    token Alternate-Protocol { [[<port> ':' <protocol>] || <directive>] *%% ','       }
    token Keep-Alive         { [<directive>]?  [";" [<.OWS> <directive> ]?]*          }
    token P3P                { [<directive>]?  [";" [<.OWS> <directive> ]?]*          }
    token Strict-Transport-Security { [<directive>]?  [";" [<.OWS> <directive> ]?]*   }

    # field-value should handle this, but doesn't. A fix for field-value should be
    # used ideally and then this can be removed
    token X-Powered-By       { <+token +space -CRLF>+                           }


    token X-Robots-Tag       { (<.token>) *%% ','                               }
    token X-XSS-Protection   { [<directive>]?  [";" [<.OWS> <directive> ]?]*    }
    token X-UA-Compatible    { [<directive>]?  [";" [<.OWS> <directive> ]?]*    }

    # todo:
    #Strict-Transport-Security # max-age=16070400; includeSubDomains
    #Link # <http://www.example.com/>; rel=”cononical”
    #X-Content-Type-Options
    #X-Frame-Options
    #Strict-Transport-Security
    #Public-Key-Pins
    #Access-Control-Allow-Origin
    #Content-Security-Policy
    #Alt-Svc
}