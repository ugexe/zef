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
    token known-header:sym<Cookie>            { [:i <.sym>] }
    token known-header:sym<Set-Cookie>        { [:i <.sym>] }
    # 7230
    token known-header:sym<Connection>        { [:i <.sym>] }
    token known-header:sym<Host>              { [:i <.sym>] }
    token known-header:sym<TE>                { [:i <.sym>] }
    token known-header:sym<Trailer>           { [:i <.sym>] }
    token known-header:sym<Transfer-Encoding> { [:i <.sym>] }
    token known-header:sym<Upgrade>           { [:i <.sym>] }
    token known-header:sym<Via>               { [:i <.sym>] }
    # 7231
    token known-header:sym<Accept>            { [:i <.sym>] }
    token known-header:sym<Accept-Charset>    { [:i <.sym>] }
    token known-header:sym<Accept-Encoding>   { [:i <.sym>] }
    token known-header:sym<Accept-Language>   { [:i <.sym>] }
    token known-header:sym<Allow>             { [:i <.sym>] }
    token known-header:sym<Content-Encoding>  { [:i <.sym>] }
    token known-header:sym<Content-Language>  { [:i <.sym>] }
    token known-header:sym<Content-Length>    { [:i <.sym>] }
    token known-header:sym<Content-Location>  { [:i <.sym>] }
    token known-header:sym<Content-Type>      { [:i <.sym>] }
    token known-header:sym<Date>              { [:i <.sym>] }
    token known-header:sym<Expect>            { [:i <.sym>] }
    token known-header:sym<From>              { [:i <.sym>] }
    token known-header:sym<Location>          { [:i <.sym>] }
    token known-header:sym<Max-Forwards>      { [:i <.sym>] }
    token known-header:sym<Referer>           { [:i <.sym>] }
    token known-header:sym<Retry-After>       { [:i <.sym>] }
    token known-header:sym<Server>            { [:i <.sym>] }
    token known-header:sym<User-Agent>        { [:i <.sym>] }
    token known-header:sym<Vary>              { [:i <.sym>] }
    # 7232
    token known-header:sym<ETag>              { [:i <.sym>] }
    token known-header:sym<Last-Modified>     { [:i <.sym>] }
    # 7233
    token known-header:sym<Accept-Ranges>     { [:i <.sym>] }
    token known-header:sym<Content-Range>     { [:i <.sym>] }
    # 7234
    token known-header:sym<Cache-Control>     { [:i <.sym>] }
    token known-header:sym<Expires>           { [:i <.sym>] }
    token known-header:sym<Warning>           { [:i <.sym>] }
    # 7235
    token known-header:sym<WWW-Authenticate>   { [:i <.sym>] }
    token known-header:sym<Proxy-Authenticate> { [:i <.sym>] }

    token header-field {
        || $<name>=<.known-header> ':' <.OWS> {} $<value>=<::($<name>)> <.OWS>
        || $<name>=<.field-name>   ':' <.OWS> $<value>=[<.field-value>] <.OWS>
    }

    token field-name    { <.token> }
    token field-value   { [<.field-content> || <.obs-fold>]*                   }
    token field-content { <.field-vchar> [<.SP> || <.HTAB> || <.field-vchar>]* }
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
