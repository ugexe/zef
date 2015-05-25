use v6;
# HTTP/1.1 Message Syntax and Routing

# TODO: write RFC5234 and inherit from that instead of 4234. 
# Then re-attempt to code proposed eratta that othewise doesn't work.

use Zef::Grammars::HTTP::RFC7231;
use Zef::Grammars::HTTP::RFC6265;

role Grammars::HTTP::Extensions {
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

    token Alternate-Protocol { [[<port> ':' <protocol>] || <directive>] *%% ',' }
    token Keep-Alive         { [<directive>]?  [";" [ <directive> ]?]*          }
    token P3P                { [<directive>]?  [";" [ <directive> ]?]*          }
    token Strict-Transport-Security { [<directive>]?  [";" [ <directive> ]?]*   }

    # field-value should handle this, but doesn't. A fix for field-value should be
    # used ideally and then this can be removed
    token X-Powered-By       { <+token +space -CRLF>+                           }


    token X-Robots-Tag       { (<.token>) *%% ','                               }
    token X-XSS-Protection   { [<directive>]?  [";" [ <directive> ]?]*          }
    token X-UA-Compatible    { [<directive>]?  [";" [ <directive> ]?]*          }

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

role Zef::Grammars::HTTP::RFC7230::Core is Zef::Grammars::HTTP::RFC7231::Core {
    also is Zef::Grammars::HTTP::RFC6265::Core;
    also does Grammars::HTTP::Extensions;

    token HTTP-message { <start-line> [<header-field> <.CRLF>]* <.CRLF> <message-body>? }
    token HTTP-header  { <start-line> [<header-field> <.CRLF>]*                         }

    token OWS   { [<.SP> || <.HTAB>]* }
    token RWS   { [<.SP> || <.HTAB>]+ }
    token BWS   { <.OWS>              }

    token Connection        { 
        [[<.OWS> <connection-option>]*] *%% ',' 
    }
    token Content-Length    { <digit>+ }
    token HTTP-version      { <HTTP-name> '/' $<major>=[\d] '.' $<minor>=[\d] }
    token HTTP-name         { 'HTTP' }
    token Host              { <host> [':' <.port>]? } # `host` from 3986
    token TE                { [[<.OWS> <t-codings>]*]       *%% ','                           }
    token Trailer           { [[<.OWS> <field-name>]*]      *%% ','                           }
    token Transfer-Encoding { [[<.OWS> <transfer-coding>]*] *%% ','                           }
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
    token known-header:sym<Etag>              { <.sym> }
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

    token field-name    { <.token> } # the general rule
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


grammar Zef::Grammars::HTTP::RFC7230 does Zef::Grammars::HTTP::RFC7230::Core {
    token TOP { <HTTP-message> }
    token TOP-Header { <HTTP-header> }
} 