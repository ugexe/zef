use Zef::Net::URI::Grammar;

# HTTP/1.1 Message Syntax and Routing
role Zef::Net::HTTP::Grammar::RFC7230 {
    token HTTP-message { <start-line> [<header-field> <.CRLF>]* <.CRLF> <message-body>? }
    token HTTP-headers { <start-line> [<header-field> <.CRLF>]* <.CRLF>                 }
    token HTTP-header  { <header-field> <.CRLF>                                         }
    token HTTP-start   { <start-line> <.CRLF>                                           }

    token OWS   { [<.SP> || <.HTAB>]* }
    token RWS   { [<.SP> || <.HTAB>]+ }
    token BWS   { <.OWS>              }

    token Connection        { 
        [[<.OWS> <connection-option>]*] *%% ',' 
    }
    token Content-Length    { <.digit>+ }
    token HTTP-version      { <HTTP-name> '/' $<major>=[\d] '.' $<minor>=[\d] }
    token HTTP-name         { 'HTTP' }
    token Host              { <host> [':' <.port>]? } # `host` from 3986
    token TE                { [[<.OWS> <t-codings>]*]       *%% ','                           }
    token Trailer           { [[<.OWS> <field-name>]*]      *%% ','                           }

    token Transfer-Encoding { <transfer-encoding-value> +%% ','                               }
    token transfer-encoding-value { [<.OWS> <transfer-coding>]                                }

    token Upgrade { [[<.OWS> <protocol>]*]                  *%% ','                           }
    token Via { [[<received-protocol> <.RWS> <received-by> [<.RWS> <comment>]?]*] *%% ','     }

    token absolute-form  { <.absolute-URI>   }
    token absolute-path  { ['/' <.segment>]+ }
    token asterisk-form  { '*'               }
    token authority-form { <.authority>      }

    token chunk             { 
        $<chunk-size>=<chunk-size>
        <chunk-ext>?
        <.CRLF>
        $<chunk-data>=[<.OCTET> ** { 1..:16("$<chunk-size>") }]
        <.CRLF>
    }
    token chunk-data        { <.OCTET>+                                                 }
    token chunk-ext         { [';' <.chunk-ext-name> ['=' <.chunk-ext-val>]?]*          }
    token chunk-ext-name    { <.token>                                                  }
    token chunk-ext-val     { <.token> || <.quoted-string>                              }
    token chunk-size        { <.xdigit>+                                                }
    token chunked-body      { <chunk>* <last-chunk> <trailer-part> <.CRLF>              }
    token comment           { '(' [<.ctext> || <.quoted-pair> || <.comment>]* ')'       }
    token connection-option { <.token> }
    token ctext { 
        <.HTAB> || <.SP> || <[\x[21]..\x[27]]> || <[\x[2A]..\x[5B]]> || <[\x[5D]..\x[7E]]> || <.obs-text> 
    }

    proto token known-header {*};
    # 6265
    token known-header:sym<Cookie>            { <.sym> }
    token known-header:sym<Set-Cookie>        { <.sym> }
    # 7230
    token known-header:sym<Connection>        { <.sym> }
    token known-header:sym<Host>              { <.sym> }
    token known-header:sym<TE>                { <.sym> }
    token known-header:sym<Trailer>           { <.sym> }
    token known-header:sym<Transfer-Encoding> { <.sym> }
    token known-header:sym<Upgrade>           { <.sym> }
    token known-header:sym<Via>               { <.sym> }
    # 7231
    token known-header:sym<Accept>            { <.sym> }
    token known-header:sym<Accept-Charset>    { <.sym> }
    token known-header:sym<Accept-Encoding>   { <.sym> }
    token known-header:sym<Accept-Language>   { <.sym> }
    token known-header:sym<Allow>             { <.sym> }
    token known-header:sym<Content-Encoding>  { <.sym> }
    token known-header:sym<Content-Language>  { <.sym> }
    token known-header:sym<Content-Length>    { <.sym> }
    token known-header:sym<Content-Location>  { <.sym> }
    token known-header:sym<Content-Type>      { <.sym> }
    token known-header:sym<Date>              { <.sym> }
    token known-header:sym<Expect>            { <.sym> }
    token known-header:sym<From>              { <.sym> }
    token known-header:sym<Location>          { <.sym> }
    token known-header:sym<Max-Forwards>      { <.sym> }
    token known-header:sym<Referer>           { <.sym> }
    token known-header:sym<Retry-After>       { <.sym> }
    token known-header:sym<Server>            { <.sym> }
    token known-header:sym<User-Agent>        { <.sym> }
    token known-header:sym<Vary>              { <.sym> }
    # 7232
    token known-header:sym<ETag>              { <.sym> }
    token known-header:sym<Last-Modified>     { <.sym> }
    # 7233
    token known-header:sym<Accept-Ranges>     { <.sym> }
    token known-header:sym<Content-Range>     { <.sym> }
    # 7234
    token known-header:sym<Cache-Control>     { <.sym> }
    token known-header:sym<Expires>           { <.sym> }
    token known-header:sym<Warning>           { <.sym> }
    # 7235
    token known-header:sym<WWW-Authenticate>   { <.sym> }
    token known-header:sym<Proxy-Authenticate> { <.sym> }

    token header-field {
        || $<name>=<.known-header> ':' <.OWS> {} $<value>=<::($<name>)> <.OWS>
        || $<name>=<.field-name>   ':' <.OWS> $<value>=[<.field-value>] <.OWS>
    }

    token field-name    { <.token> }
    token field-value   { [<.field-content> || <.obs-fold>]*                     }
    token field-content { <.field-vchar> [[<.SP> || <.HTAB> || <.field-vchar>]* <.field-vchar>]? }
    token field-vchar   { <.VCHAR> || <.obs-text>  }
    token last-chunk    { 0+ <.chunk-ext>? <.CRLF> }

    token message-body  { <.OCTET>* }
    token method        { GET || HEAD || POST || PUT || DELETE || CONNECT || OPTIONS || TRACE }

    token obs-fold      { <.OWS> <.CRLF> [<.SP> || <.HTAB>]+ }
    token obs-text      { <[\x[80]..\x[FF]]>                 }
    token origin-form   { <.absolute-path> [ '?' <.query> ]? }
    
    token protocol         { <.protocol-name> ['/' <.protocol-version>]? }
    token protocol-name    { <.token> }
    token protocol-version { <.token> }
    token pseudonym        { <.token> }

    token quoted-string { <.DQUOTE> [<.qdtext> || <.quoted-pair>]* <.DQUOTE> }
    token quoted-pair   { \x[92] [<.HTAB> || <.SP> || <.VCHAR> || <.obs-text>]      }
    token qdtext        { <.HTAB> || <.SP> || \x[21] || <[\x[23]..\x[5B]]> || <[\x[5D]..\x[7E]]> || <.obs-text> }

    token rank              { [0 ['.' \d\d?\d?]?] || [1 ['.' 0?0?]?]                   }
    token reason-phrase     { [<.HTAB> || <.SP> || <.VCHAR> || <.obs-text>]*           } 
    token received-by       { [<.host> [':' <.port>]?] || <.pseudonym>             }
    token received-protocol { [<.protocol-name> '/']? <.protocol-version>              }
    token request-line      { <method> ' ' <request-target> ' ' <HTTP-version> <.CRLF> }
    token request-target    { <.origin-form> || <.absolute-form> || <.authority-form> || <.asterisk-form> }

    token start-line  { <request-line> || <status-line> }
    token status-line { <HTTP-version> <.SP> <status-code> <.SP> <reason-phrase> <.CRLF> }
    token status-code { \d\d\d }


    token t-codings    { 'trailers' || [<.transfer-coding> <.t-ranking>?]         }
    token t-ranking    { <.OWS> ';' <.OWS> 'q=' <rank>                            }
    token tchar        { 
        || < ! # $ % & ' * + - . ^ _ ` | ~ > 
        || <.DIGIT>
        || <.ALPHA> 
    }
    token token        { <.tchar>+ }
    token trailer-part { [<.header-field> <.CRLF>]* }
    token transfer-coding { 
        || 'chunked'
        || 'compress'
        || 'deflate'
        || 'gzip'
        || <transfer-extension>
    }
    token transfer-extension { <.token> [<.OWS> ';' <.OWS> <.transfer-parameter>]*       }
    token transfer-parameter { <.token> <.BWS> '=' <.BWS> [<.token> || <.quoted-string>] }

    token delimiters { [< ( ) , / : ; = ? @ [ \ ] { } > || '<' || '>']+ }
}




# Hypertext Transfer Protocol (HTTP/1.1): Semantics and Content
role Zef::Net::HTTP::Grammar::RFC7231  {
    # note: tokens with `-value` postfix were added to help resolve 
    # quantification I haven't figured out. 
    token Accept           { <accept-value> +%% ','                                  }
    token accept-value     { [<.OWS> <media-range> <.OWS> [<accept-params> <.OWS>]?] }

    token Accept-Charset   { <accept-charset-value> +%% ','              }
    token accept-charset-value { [<.OWS> [[<charset> || '*'] <weight>?]] }

    token Accept-Encoding  { <accept-encoding-value> +%% ','     }
    token accept-encoding-value { [<.OWS> [<codings> <weight>?]] }

    token Accept-Language  { <accept-language-value> +%% ','            }
    token accept-language-value { [<.OWS> [<language-range> <weight>?]] }

    token Allow            { <allow-value> +%% ',' }
    token allow-value      { [<.OWS> <method>]     }

    token Content-Encoding { <content-encoding-value> +%% ',' }
    token content-encoding-value { [<.OWS> <content-coding>]  }

    token Content-Language { <content-language-value> +%% ','  }
    token content-language-value { [<.OWS> <content-language>] }

    token Content-Location { <absolute-URI> || <partial-URI> }
    token Content-Type  { <media-type>   }
    token Date          { <HTTP-date>    }
    token Expect        { '100-continue' }
    token From          { <mailbox>      }
    token GMT           { [:!i GMT]      }
    token HTTP-date     { <IMF-fixdate> || <obs-date> }
    token IMF-fixdate   { <day-name> ',' <.SP> <date1> <.SP> <time-of-day> <.SP> <GMT> }
    token Location      { <URI-reference> }
    token Max-Forwards  { <digit> }
    token Referer       { <absolute-URI> || <partial-URI> }
    token Retry-After   { <HTTP-date> || <delay-seconds>  }
    token Server        { <product> [<.RWS> [<product> || <comment>]]* }
    token User-Agent    { <product> [<.RWS> [<product> || <comment>]]* }
    token Vary { <vary-value> +%% ',' }
    token vary-value {
        || '*' 
        || [<.OWS> <field-name>]        
    }
    token accept-ext    { <.OWS> ';' <.OWS> $<name>=<.token> ['=' $<value>=[<.token> || <.quoted-string>]]? }
    token accept-params { <weight> <accept-ext>* }
    token asctime-date  { <day-name> <.SP> <date3> <.SP> <time-of-day> <.SP> <year> }

    token charset { <.token> }
    token codings { <.content-coding> || 'identity' || '*' }
    token content-coding { <.token> }

    token date1 { <day> <.SP> <month> <.SP> <year>     }
    token date2 { <day> '-' <month> '-' $<year>=(\d\d) }
    token date3 { <month> <.SP> [(\d\d) || (<.SP>\d)]  }
    token day   { \d\d }
    token day-name {
        || Mon
        || Tue
        || Wed
        || Thu
        || Fri
        || Sat
        || Sun
    }
    token day-name1 {
        || Monday
        || Tuesday
        || Wednesday
        || Thursday
        || Friday
        || Saturday
        || Sunday
    }
    token delay-second { \d }

    # Eratta 4225
    #token field-name { <.comment> }

    token hour { \d\d }

    # token mailbox = <mailbox, see [RFC5322], Section 3.4>

    token media-range {
        [
        || [$<type>='*' '/' $<subtype>='*']
        || [<type>      '/' $<subtype>='*'] 
        || [<type>      '/' <subtype>     ]
        ]
        [
        [<.OWS> ';' <.OWS> <parameter>]*
        ]?
    }

     token media-type { <type> '/' <subtype> [<.OWS> ';' <.OWS> <parameter>]* }
     token minute     { \d\d }
     token month      {
        || Jan
        || Feb
        || Mar
        || Apr
        || May
        || Jun
        || Jul
        || Aug
        || Sep
        || Oct
        || Nov
        || Dec
    }

    token obs-date { <rfc850-date> || <asctime-date> }

    # The "q" parameter is necessary if any extensions (accept-ext) are present, 
    # since it acts as a separator between the two parameter sets.
    token parameter       { <!before 'q='> $<name>=<.token> '=' $<value>=[<.token> || <.quoted-string>] }
    
    token product         { <.token> ['/' <product-version>]? }
    token product-version { <.token> }

    token qvalue { 
        || [0 ['.' \d?\d?\d?]?] 
        || [1 ['.' 0?0?0?]?]
    }

    token rfc850-date  { <day-name1> ',' <.SP> <date2> <.SP> <time-of-day> <.SP> <.GMT> }
    token second       { \d\d }
    token type         { <.token> }
    token subtype      { <.token> }
    token time-of-day  { <hour> ':' <minute> ':' <second> }
    token weight       { <.OWS> ';' <.OWS> 'q=' <qvalue>  }
    token year         { \d\d\d\d }
} 




# Hypertext Transfer Protocol (HTTP/1.1): Conditional Requests
role Zef::Net::HTTP::Grammar::RFC7232 {
    token ETag { <.entity-tag> }

    token If-Match {
        ||  '*'
        ||  [[<.OWS> <entity-tag>]*] *%% ','
    }

    token If-Modified-Since { <.HTTP-date> }

    token If-None-Match {
        || '*'
        || [[<.OWS> <entity-tag>]*] *%% ','
    }

    token If-Unmodified-Since { <.HTTP-date> }
    token Last-Modified       { <.HTTP-date> }


    token entity-tag { <.weak>? <.opaque-tag> }

    token etagc { 
        || '!'
        || <[\x[23]..\x[7E]]>
        || <.obs-text>
    }

    token opaque-tag { <.DQUOTE> <.etagc>* <.DQUOTE> }
    token weak       { \x[57]\x[2F]                  }
}




# Hypertext Transfer Protocol (HTTP/1.1): Range Requests
role Zef::Net::HTTP::Grammar::RFC7233 {
    token Accept-Ranges { [<acceptable-ranges> + %% ','] || 'none' }
    token Content-Range { <.byte-content-range> || <.other-content-range> }

    token If-Range { <.entity-tag> || <.HTTP-date> }

    token Range { <.byte-ranges-specifier> || <.other-ranges-specifier>     }

    token acceptable-ranges  { [[<.OWS> <range-unit>]*] }

    token byte-content-range { <.bytes-unit> <.SP> [<.byte-range-resp> || <.unsatisfied-range>]  }
    token byte-range         { <.first-byte-pos> '-' <.last-byte-pos>                            }
    token byte-range-resp    { <.byte-range> '/' [<.complete-length> || '*']                     }

    token byte-range-set { <byte-range-set-value> +%% ',' }
    token byte-range-set-value { [[<.OWS> [<.byte-range-spec> || <.suffix-byte-range-spec>]]*] }

    token byte-range-spec       { <.first-byte-pos> '-' <.last-byte-pos>? }
    token byte-ranges-specifier { <.bytes-unit> '=' <.byte-range-set>     }
    token bytes-unit            { 'bytes'   }
    token complete-length       { <.DIGIT>+ }

    token first-byte-pos { <.DIGIT>+ }
    token last-byte-pos  { <.DIGIT>+ }

    token other-content-range    { <.other-range-unit> <.SP> <.other-range-resp> }
    token other-range-resp       { <.CHAR>*                                      }
    token other-range-set        { <.VCHAR>+                                     }
    token other-range-unit       { <.token>                                      }
    token other-ranges-specifier { <.other-range-unit> '=' <.other-range-set>    }
    token range-unit             { <.bytes-unit> || <.other-range-unit>          }
    token suffix-byte-range-spec { '-' <.suffix-length>                          }
}




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




# Update to Internet Message Format to Allow Group Syntax in the "From:" and "Sender:" Header Fields
role Zef::Net::HTTP::Grammar::RFC6854 {
    my token from     { "From:" [<mailbox-list> || <address-list>] <.CRLF> }
    my token sender   { "Sender:" [<mailbox> || <address>] <.CRLF>         }
    my token reply-to { "Reply-To:" <address-list> <.CRLF>                 }

    my token resent-from   { "Resent-From:" [<mailbox-list> || <address-list>] <.CRLF> }
    my token resent-sender { "Resent-Sender:" [<mailbox> || <address>] <.CRLF>         }
}




# HTTP State Management Mechanism
role Zef::Net::HTTP::Grammar::RFC6265 {
    my token obs-fold { <.CRLF>               }

    # this token does not come from this RFC
    # todo: s/<date2>/lexical month/day/year tokens/
    token rfc1123-date { [<.day-of-week> ',']? <.SP> [<date2>\d\d] <.SP> <.time-of-day> <.SP> 'GMT' }

    token set-cookie-header { 'Set-Cookie:' <.SP> <Set-Cookie>   }
    token Set-Cookie   { <cookie-pair> [';' <.SP> <cookie-av>]*  } # renamed from RFC for our indirect method call 
                                                                   # in proto token known-header in RFC7230.pm6
    token cookie-pair  { <cookie-name> '=' <cookie-value>                      }
    token cookie-name  { <.token>                                              }
    token cookie-value { <.cookie-octet>* || <.DQUOTE> <.cookie-octet>* <.DQUOTE> }
    token cookie-octet { 
        || \x[21] 
        || <[\x[23]..\x[2B]]> 
        || <[\x[2D]..\x[3A]]> 
        || <[\x[3C]..\x[5B]]>
        || <[\x[5D]..\x[7E]]>
    }

    # Conflicts with 7230
    # token delimiters { [< ( ) , / : ; = ? @ [ \ ] { } > || '<' || '>']+ }

    my token token { <+CHAR -delimiters -QUOTE -SP -HTAB -CTL>+  }
    token cookie-av { 
        || <expires-av>
        || <max-age-av>
        || <domain-av>
        || <path-av>
        || <secure-av>
        || <httponly-av>
        || <extension-av>
    }
    token expires-av        { [:i 'Expires=' ] <sane-cookie-date> }
    token max-age-av        { [:i 'Max-Age=' ] [1..9] <.DIGIT>*   }
    token domain-av         { [:i 'Domain='  ] <domain-value>     }
    token secure-av         { [:i 'Secure'   ]                    }
    token httponly-av       { [:i 'HttpOnly' ]                    }
    token path-av           { [:i 'Path='    ] <path-value>       }
    token sane-cookie-date  { <rfc1123-date>                      }
    token domain-value      { <subdomain>                         }
    token path-value        { <+CHAR -CTL -[;]>                   }
    token extension-av      { <+CHAR -CTL -[;]>                   }

    token cookie-header { 'Cookie:' <.OWS> <cookie-string> <.OWS>       }
    token cookie-string { <cookie-pair> [';' <.SP> <cookie-pair>]*      }
    token cookie-date   { <.delimiter>* <date-token-list> <.delimiter>* }
    token date-token-list { <date-token> [<.delimiter>+ <date-token>]*  }
    my token date-token      { <.non-delimiter>+ }
    my token delimiter       { 
        || \x[09] 
        || <[\x[20]..\x[2F]]> 
        || <[\x[3B]..\x[40]]> 
        || <[\x[5B]..\x[60]]> 
        || <[\x[7B]..\x[7E]]>     
    }
    my token non-delimiter   { 
        || <[\x[00]..\x[08]]> 
        || <[\x[0A]..\x[1F]]> 
        || <DIGIT> 
        || ':' 
        || <ALPHA> 
        ||  <[\x[7F]..\x[FF]]>  
    }

    # Errata ID: 4148
    my token day-of-month { <DIGIT> ** 1..2 [<non-digit> <OCTET>*]? }
    my token non-digit    { <[\x[00]..\x[2F]]> ||  <[\x[3A]..\x[FF]]> }
    my token month        { [jan || feb || mar || apr || may || jun || jul || aug || sep || oct || nov || dec] <OCTET>* }
    my token year         { <DIGIT> ** 2..4 [<non-digit> <OCTET>*]? }
    my token time         { <hms-time> [<non-digit> <OCTET>*]? }
    my token hms-time     { <time-field> ':' <time-field> ':' <time-field> }
    my token time-field   { <DIGIT> ** 1..2 }
}




# Tags for Identifying Languages
role Zef::Net::HTTP::Grammar::RFC5646 {
    token langtag { 
        <language>
        ['-' <script>]?
        ['-' <region>]?
        ['-' <variant>]*
        ['-' <extension>]*
        ['-' <privateuse>]?
    }

    token language { 
        | [ <.ALPHA> ** 2..3 ['-' <.extlang>]? ] 
        | [ <.ALPHA> ** 4    ]
        | [ <.ALPHA> ** 5..8 ]
    }

    token extlang { 
        [<.ALPHA> ** 3] 
        ['-' [<.ALPHA> ** 3]] ** 0..2
    }

    token script { <.ALPHA> ** 4 }

    token region { 
        | <.ALPHA> ** 2
        | <.DIGIT> ** 3
    }

    token variant {
        | <.alphanum> ** 5..8
        | <.DIGIT> <.alphanum> ** 3
    }

    token extension { <.singleton> ['-' <.alphanum> ** 2..8]+ }

    token singleton { <+alphanum -[xX]> }

    token privateuse { 'x' ['-' <.alphanum> ** 5..8]+ }

    token grandfathered { <.irregular> | <.regular> }

    token irregular {
        | 'en-GB-ied'
        | 'i-ami'
        | 'i-bnn'
        | 'i-default'
        | 'i-enochian'
        | 'i-hak'
        | 'i-klingon'
        | 'i-lux'
        | 'i-mingo'
        | 'i-navajao'
        | 'i-pwn'
        | 'i-tao'
        | 'i-tay'
        | 'i-tsu'
        | 'sgn-BE-FR'
        | 'sgn-BE-NL'
        | 'sgn-CH-DE'
    }

    token regular {
        | 'art-lojban'
        | 'cel-gaulish'
        | 'no-bok'
        | 'no-nyn'
        | 'zh-guoyu'
        | 'zh-hakka'
        | 'zh-min'
        | 'zh-min-nan'
        | 'zh-xiang'
    }

    token alphanum { <.ALPHA> | <.DIGIT> } 
}




# Internet Message Format
role Zef::Net::HTTP::Grammar::RFC5322 {

    my token quoted-pair { [\\ [<.VCHAR> || <.WSP>]] || <.obs-qp> }

    my token FWS { [[<.WSP>* <.CRLF>]? <.WSP>+] || <.obs-FWS> }

    my token ctext { <[\c[33]..\c[39]\c[42]..\c[91]\c[93]..\c[126]]> || <.obs-ctext> }

    my token ccontent { <.ctext> || <.quoted-pair> || <.comment> }
    my token comment { '(' [<.FWS>? <.ccontent>]* <.FWS>? ')' }

    my token CFWS { [[<.FWS>? <.comment>]+ <.FWS>?] || <.FWS> }

    my token atext { 
        || <.ALPHA>  
        || <.DIGIT>
        || < ! # $ %  & ' * + - | = ? ^ _ ` { | } ~ >
    }

    my token atom { <.CFWS>? <.atext>+ <.CFWS>? }

    my token dot-atom-text { <.atext>+ ['.' <.atext>+]* }
    my token dot-atom { <.CFWS>? <.dot-atom-text> <.CFWS>? }

    my token qtext { <[\c[33]\c[35]..\c[91]\c[93]..\c[126]]> || <.obs-qtext> }

    my token qcontent { <.qtext> || <.quoted-pair> }

    my token quoted-string { <.CFWS>? '"' [<.FWS>? <.qcontent>]* <.FWS>? '"' <.CFWS>? }

    my token word { <.atom> || <.quoted-string> }

    my token phrase { <.word>+ || <.obs-phrase> }

    my token unstructured { [[<.FWS>? <.VCHAR>]* <.WSP>*] || <.obs-unstruct> }

    my token date-time { [<.day-of-week> ',']? <.date> <.time> <.CFWS>? }

    my token day-of-week { [<.FWS>? <.day-name>] || <.obs-day-of-week> }

    my token day-name { 'Mon' || 'Tue' || 'Wed' || 'Thu' || 'Fri' || 'Sat' || 'Sun' }

    my token date { <day> <month> <year> }

    my token day { [<.FWS>? [<.DIGIT> ** 1..2] <.FWS>] || <.obs-day> }

    my token month { 'Jan' || 'Feb' || 'Mar' || 'Apr' || 'May' || 'Jun' || 'Jul' || 'Aug' || 'Sep' || 'Oct' || 'Nov' || 'Dec'}

    my token year { 
        ||  [   
            <.FWS> 
            <.DIGIT> ** 4  # i.e.
            <.DIGIT>*      # <.DIGIT> ** 4..Inf
            <.FWS>
            ] 
        ||  <.obs-year> 
    }

    my token time { <.time-of-day> <.zone> }

    my token time-of-day { <.hour> ':' <.minute> [':' <.second>]? }

    my token hour { [<.DIGIT> ** 2] || <.obs-hour> }

    my token minute { [<.DIGIT> ** 2] || <.obs-minute> }

    my token second { [<.DIGIT> ** 2] || <.obs-second> }

    my token zone { [<.FWS> ['+' || '-'] [<.DIGIT> ** 4]] || <.obs-zone> }

    my token address { <mailbox> || <group> }

    my token mailbox { <name-addr> || <addr-spec> }

    my token name-addr { <display-name>? <angle-addr> }

    my token angle-addr { [<.CFWS>? '<' <addr-spec> '>' <.CFWS>?] || <.obs-angle-addr> }

    my token group { <display-name> ':' <group-list>? ';' <.CFWS>? }

    my token display-name { <.phrase> }

    my token mailbox-list { [<mailbox> *%% ','] || <obs-mbox-list> }

    my token address-list { [<address> *%% ','] || <obs-addr-list> }

    my token group-list { <mailbox-list> || <.CFWS> || <obs-group-list> }

    my token addr-spec { <.local-part> '@' <.domain> }

    my token local-part { <.dot-atom> || <.quoted-string> || <.obs-local-part> }

    my token domain { <.dot-atom> || <.domain-literal> || <.obs-domain> }

    my token domain-literal { <.CFWS>? '[' [<.FWS>? <.dtext>]* <.FWS>? ']' <.CFWS>? }

    my token dtext { <[\c[33]..\c[90]\c[94]..\c[126]]> || <.obs-dtext> }

    my token message { [<fields> || $<fields>=<.obs-fields>] [<.CRLF> <body>]? }

    my token body { [[[<.text> ** 0..998] <.CRLF>]* [<.text> ** 0..998]] || <.obs-body> }

    my token text { <[\c[1]..\c[9]\c[11,12]\c[14]..\c[127]]> }

    my token fields {
        [
        <trace>
            [   
            || <resent-date>
            || <resent-from>
            || <resent-sender>
            || <resent-to>
            || <resent-cc>
            || <resent-bcc>
            || <resent-msg-id>
            ]*
        ]*
        [
        || <orig-date>
        || <from>
        || <sender>
        || <reply-to>
        || <to>
        || <cc>
        || <bcc>
        || <message-id>
        || <in-reply-to>
        || <references>
        || <subject>
        || <comments>
        || <keywords>
        || <optional-field>
        ]*
    }

    my token orig-date { "Date:" <date-time> <.CRLF> }

    my token from { "From:" <mailbox-list> <.CRLF> }

    my token sender { "Sender:" <mailbox> <.CRLF> }

    my token reply-to { "Reply-To:" <address-list> <.CRLF> }

    my token to { "To:" <address-list> <.CRLF> }

    my token cc { "Cc:" <address-list> <.CRLF> }

    my token bcc { "Bcc:" [<address-list> || <.CFWS>]? <.CRLF> }

    my token message-id { "Message-ID:" <msg-id> <.CRLF> }

    my token in-reply-to { "In-Reply-To:" <msg-id>+ <.CRLF> }

    my token references { "References:" <msg-id>+ <.CRLF> }

    my token msg-id { <.CFWS>? '<' <.id-left> '@' <.id-right> '>' <.CFWS>? }

    my token id-left  { <.dot-atom-text> || <.obs-id-left> }

    my token id-right { <.dot-atom-text> || <.no-fold-literal> || <.obs-id-left> }

    my token no-fold-literal { '[' <.dtext>* ']' }

    my token subject { "Subject:" $<value>=<.unstructured> <.CRLF> }

    my token comments { "Comments:" (<.unstructured>) <.CRLF> }

    my token keywords { "Keywords:" [<phrase> *%% ','] <.CRLF> }

    my token resent-date { "Resent-Date:" <.date-time> <.CRLF> }

    my token resent-from { "Resent-From:" <.mailbox-list> <.CRLF> }

    my token resent-sender { "Resent-Sender:" <.mailbox> <.CRLF> }

    my token resent-to { "Resent-To:" <.address-list> <.CRLF> }

    my token resent-cc { "Resent-Cc:" <.address-list> <.CRLF> }

    my token resent-bcc { "Resent-Bcc:" [<.address-list> || <.CFWS>] <.CRLF> }

    my token resent-msg-id { "Resent-Message-ID:" <.msg-id> <.CRLF> }

    my token trace { <return>? <received>+ }

    my token return { "Return-Path:" <path> <.CRLF> }

    my token path { <.angle-addr> || [<.CFWS>? '<' <.CFWS>? '>' <.CFWS>?] }

    # Errata ID: 3979 
    my token received { "Received:" [<received-token>+ || <.CFWS>] ';' <date-time> <.CRLF> }

    my token received-token { <.word> || <.angle-addr> || <.addr-spec> || <.domain> }

    my token optional-field { $<field>=<.field-name> ':' $<value>=<.unstructured> <.CRLF> }

    my token field-name { <.ftext>+ }

    my token ftext { <[\c[33]..\c[57]\c[59]..\c[126]]> }

    my token obs-NO-WS-CTL { <[\c[1]..\c[8]\c[11,12]\c[14]..\c[31]\c[127]]> }

    my token obs-ctext { <.obs-NO-WS-CTL> }

    my token obs-qtext { <.obs-NO-WS-CTL> }

    my token obs-utext { \c[0] || <.obs-NO-WS-CTL> || <.VCHAR> }

    my token obs-qp { \\ [\c[0] || <.obs-NO-WS-CTL> || <.LF> || <.CR>] }

    my token obs-body { [[<.LF>* <.CR>* [[\c[0] || <.text>] <.LF>* <.CR>*]*] || <.CRLF>]* }

    #Errata ID: 1905
    my token obs-unstruct { [[<.CR>* [<.obs-utext> || <.FWS>]+] || <.LF>+ ]* <.CR>* }

    my token obs-phrase { <.word> [<.word> || '.' || <.CFWS>]* }

    my token obs-phrase-list { [<.phrase> || <.CFWS>]? [',' [<.phrase> || <.CFWS>]?]* }

    # Errata ID: 1908
    my token obs-FWS { [<.CRLF>? <.WSP>]+ }

    my token obs-day-of-week { <.CFWS>? <.day-name> <.CFWS>? }

    my token obs-day { <.CFWS>? <.DIGIT> ** 1..2 <.CFWS>? }

    my token obs-year { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    my token obs-hour { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    my token obs-minute { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    my token obs-second { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    my token obs-zone { 
        || 'UT'  || 'GMT'
        || 'EST' || 'EDT'
        || 'CST' || 'CDT'
        || 'MST' || 'MDT'
        || 'PST' || 'PDT'
        || <[\c[65]..\c[73]]>
        || <[\c[75]..\c[90]]>
        || <[\c[97]..\c[105]]>
        || <[\c[107]..\c[122]]>
    }

    my token obs-angle-addr { <.CFWS>? '<' <.obs-route> <.addr-spec> '>' <.CFWS>? }

    my token obs-route { <.obs-domain-list> ':'}

    my token obs-domain-list { [<.CFWS>? || ',']* '@' <.domain> [',' <.CFWS>? ['@' <.domain>]]* }

    my token obs-mbox-list { [<.CFWS>? ',']* <.mailbox> [',' [<.mailbox> || <.CFWS>]?]* }

    my token obs-addr-list { [<.CFWS>? ',']* <.address> [',' [<.address> || <.CFWS>]?]* }

    my token obs-group-list { [<.CFWS>? ',']+ <.CFWS>? }

    my token obs-local-part { <.word> ['.' <.word>]* }

    my token obs-domain { <.atom> ['.' <.atom>]* }

    my token obs-dtext { <.obs-NO-WS-CTL> || <.quoted-pair> }

    my token obs-fields {
        [
        || <obs-return>
        || <obs-received>
        || <obs-orig-date>
        || <obs-from>
        || <obs-sender>
        || <obs-reply-to>
        || <obs-to>
        || <obs-cc>
        || <obs-bcc>
        || <obs-message-id>
        || <obs-in-reply-to>
        || <obs-references>
        || <obs-subject>
        || <obs-comments>
        || <obs-keywords>
        || <obs-resent-date>
        || <obs-resent-from>
        || <obs-resent-send>
        || <obs-resent-rply>
        || <obs-resent-to>
        || <obs-resent-cc>
        || <obs-resent-bcc>
        || <obs-resent-mid>
        || <obs-optional>
        ]*
    }

    my token obs-orig-date { "Date" <.WSP>* ':' <.date-time> <.CRLF> }

    my token obs-from { "From" <.WSP>* ':' <.mailbox-list> <.CRLF> }

    my token obs-sender { "Sender" <.WSP>* ':' <.mailbox> <.CRLF> }

    my token obs-reply-to { "Reply-To" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-to { "To" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-cc { "Cc" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-bcc { "Bcc" <.WSP>* ':' [<.address-list> || [[<.CFWS>? ',']* <.CFWS>?]] <.CRLF> }

    my token obs-message-id { "Message-ID" <.WSP>* ':' <.msg-id> <.CRLF> }

    my token obs-in-reply-to { "In-Reply-To" <.WSP>* ':' [<.phrase> || <.msg-id>] <.CRLF> }

    my token obs-references { "References" <.WSP>* ':' [<.phrase> || <.msg-id>] <.CRLF> }

    my token obs-id-left { <.local-part> }

    my token obs-id-right { <.domain> }

    my token obs-subject { "Subject" <.WSP>* ':' <.unstructured> <.CRLF> }

    my token obs-comments { "Comments" <.WSP>* ':' <.unstructured> <.CRLF> }

    my token obs-keywords { "Keywords" <.WSP>* ':' <.obs-phrase-list> <.CRLF> }

    my token obs-resent-from { "Resent-From" <.WSP>* ':' <.mailbox-list> <.CRLF> }

    my token obs-resent-send { "Resent-Sender" <.WSP>* ':' <.mailbox> <.CRLF> }

    my token obs-resent-date { "Resent-Date" <.WSP>* ':' <.date-time> <.CRLF> }

    my token obs-resent-to { "Resent-To" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-resent-cc { "Resent-Cc" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-resent-bcc { "Resent-Bcc" <.WSP>* ':' [<.address-list> || [[<.CFWS>? ',']* <.CRLF>?]] <.CRLF> }

    my token obs-resent-mid { "Resent-Message-ID" <.WSP>* ':' <.msg-id> <.CRLF> }

    my token obs-resent-rply { "Resent-Reply-To" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-return { "Return-Path" <.WSP>* ':' <.path> <.CRLF> }

    # Errata ID: 3979
    my token obs-received { "Received" <.WSP>* ':' [<.received-token>+ || <.CFWS>] <.CRLF> }

    my token obs-optional { <.field-name> <.WSP>* ':' <.unstructured> <.CRLF> }
}




# Matching of Language Tags
role Zef::Net::HTTP::Grammar::RFC4647 {
    token language-range          { <language-tag> || '*'                              }
    token extended-language-range { [<primary-subtag> || '*'] ['-' [<subtag> || '*']]* }
}




# Tags for Identification of Languages
role Zef::Net::HTTP::Grammar::RFC3066 {
    token language-tag   { <primary-subtag> ['-' <subtag>]* }
    token primary-subtag { <.ALPHA> ** 1..8                 }
    token subtag         { [<.ALPHA> || <.DIGIT>] ** 1..8   }
}




# DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION
# token subdomain has been modified. could not get it to work otherwise.
role Zef::Net::HTTP::Grammar::RFC1035 {
    token letter      { [a..zA..Z] }
    token digit       { [0..9]     }
    token domain      { <subdomain> || ' '                        }
    token subdomain   { <+alpha +digit>* ['.' <+alpha +digit>+]+  }
    token label       { <.let-dig-hyp>* <.let-dig>+               }
    token let-dig-hyp { <.let-dig>+ '-'                           }
    token let-dig     { <.letter> || <.digit>                     }
}




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



# Mix in all the various RFCs into a usable grammar
grammar Zef::Net::HTTP::Grammar {
    also does Zef::Net::HTTP::Grammar::Extensions;
    also does Zef::Net::HTTP::Grammar::RFC1035;
    also does Zef::Net::HTTP::Grammar::RFC3066;
    also does Zef::Net::HTTP::Grammar::RFC4647;
    also does Zef::Net::HTTP::Grammar::RFC5322;
    also does Zef::Net::HTTP::Grammar::RFC5646;
    also does Zef::Net::HTTP::Grammar::RFC6265;
    also does Zef::Net::HTTP::Grammar::RFC6854;
    also does Zef::Net::HTTP::Grammar::RFC7230;
    also does Zef::Net::HTTP::Grammar::RFC7231;
    also does Zef::Net::HTTP::Grammar::RFC7232;
    also does Zef::Net::HTTP::Grammar::RFC7233;
    also does Zef::Net::HTTP::Grammar::RFC7234;
    also does Zef::Net::HTTP::Grammar::RFC7235;
    also does Zef::Net::URI::Grammar::RFC3986;
    also does Zef::Net::URI::Grammar::RFC4234;

    token TOP         { <HTTP-message> }
    token TOP-start   { <HTTP-start>   }
    token TOP-headers { <HTTP-headers> }
    token TOP-header  { <HTTP-header>  }
    # token TOP-trailer { <HTTP-trailer> }
}