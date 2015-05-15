use v6;
# HTTP/1.1 Message Syntax and Routing

# TODO: write RFC5234 and inherit from that instead of 4234. 
# Then re-attempt to code proposed eratta that othewise doesn't work.

use Zef::Grammars::HTTP::RFC7231;
use Zef::Grammars::HTTP::RFC6265;
#use Grammar::Debugger;
role Zef::Grammars::HTTP::RFC7230::Core is Zef::Grammars::HTTP::RFC7231::Core {
    also is Zef::Grammars::HTTP::RFC6265::Core;

    token HTTP-message { <start-line> [<header-field> <.CRLF>]* <.CRLF> <message-body>? }

    token OWS   { [<.SP> || <.HTAB>]* }
    token RWS   { [<.SP> || <.HTAB>]+ }
    token BWS   { <.OWS>              }

    # fields
    token Connection        { 
        [',' <.RWS>]* <connection-option> [<.RWS> ',' [<.space> <connection-option>]?]* 
    }
    token Content-Length    { [0..9]+ }
    token HTTP-version      { <HTTP-name> '/' $<major>=[\d] '.' $<minor>=[\d] }
    token HTTP-name         { 'HTTP' }
    token Host              { <host> [':' <.port>]? } # `host` from 3986
    token TE                { [ [',' || <t-codings>] [<.OWS> ',' [<.OWS> <t-codings>]?]*]?    }
    token Trailer           { [',' <.OWS>]* <field-name> [<.OWS> ',' [<.OWS> <field-name>]?]* }
    token Transfer-Encoding { 
        [',' <.OWS>]* <transfer-coding> [<.OWS> ',' [<.OWS> <transfer-coding>]?]* 
    }
    token Upgrade { [',' <.OWS>]* <protocol> [<.OWS> ',' [<.OWS> <protocol>]?]*     }
    token Via {
        [',' <.OWS>]*
        [<received-protocol> <.RWS> <received-by> [<.RWS> <comment>]?]
        [<.OWS> ',' [<.OWS> [<received-protocol> <.RWS> <received-by> [<.RWS> <comment>]?]]?]*
    }

    token absolute-form  { <.absolute-URI>   }
    token absolute-path  { ['/' <.segment>]+ }
    token asterisk-form  { '*'               }
    token authority-form { <.authority>      }

    token chunk             { <.chunk-size> <.chunk-ext>? <.CRLF> <.chunk-data> <.CRLF> }
    token chunk-data        { <.OCTET>+                                                 }
    token chunk-ext         { [';' <.chunk-ext-name> ['=' <.chunk-ext-val>]?]*          }
    token chunk-ext-name    { <.token>                                                  }
    token chunk-ext-val     { <.token> || <.quoted-string>                              }
    token chunk-size        { <.xdigit>+                                                }
    token chunked-body      { <.chunk>* <.last-chunk> <.trailer-part> <.CRLF>           }
    token comment           { '(' [<.ctext> || <.quoted-pair> || <.comment>]* ')'       }
    token connection-option { <.token> }
    token ctext { 
        <.HTAB> || <.SP> || <[\x[21]..\x[27]]> || <[\x[2A]..\x[5B]]> || <[\x[5D]..\x[7E]]> || <.obs-text> 
    }

    token delimiters { <[\(\)\,\/\:\;\<\=\>\?\@\[\\\]\{\}]>+ }

    
    # todo: refactorrr
    token header-field  { 
        # 7230
        || $<name>=["Connection"]        ':' <.OWS> <Connection>
        || $<name>=["Host"]              ':' <.OWS> <Host>
        || $<name>=["TE"]                ':' <.OWS> <TE>
        || $<name>=["Trailer"]           ':' <.OWS> <Trailer>
        || $<name>=["Transfer-Encoding"] ':' <.OWS> <Transfer-Encoding>
        || $<name>=["Upgrade"]           ':' <.OWS> <Upgrade>
        || $<name>=["Via"]               ':' <.OWS> <Via>

        # 7231
        || $<name>=["Accept"]            ':' <.OWS> <Accept>
        || $<name>=["Accept-Charset"]    ':' <.OWS> <Accept-Charset>
        || $<name>=["Accept-Encoding"]   ':' <.OWS> <Accept-Encoding>
        || $<name>=["Accept-Language"]   ':' <.OWS> <Accept-Language>
        || $<name>=["Allow"]             ':' <.OWS> <Allow>
        || $<name>=["Content-Encoding"]  ':' <.OWS> <Content-Encoding>
        || $<name>=["Content-Language"]  ':' <.OWS> <Content-Language>
        || $<name>=["Content-Location"]  ':' <.OWS> <Content-Location>
        || $<name>=["Content-Type"]      ':' <.OWS> <Content-Type>
        || $<name>=["Date"]              ':' <.OWS> <Date>
        || $<name>=["Expect"]            ':' <.OWS> <Expect>
        || $<name>=["From"]              ':' <.OWS> <From>
        || $<name>=["Location"]          ':' <.OWS> <Location>
        || $<name>=["Max-Forwards"]      ':' <.OWS> <Max-Forwards>
        || $<name>=["Referer"]           ':' <.OWS> <Referer>
        || $<name>=["Retry-After"]       ':' <.OWS> <Retry-After>
        || $<name>=["Server"]            ':' <.OWS> <Server>
        || $<name>=["User-Agent"]        ':' <.OWS> <User-Agent>
        || $<name>=["Vary"]              ':' <.OWS> <Vary>

        # 6265
        || $<name>=["Cookie"]            ':' <.OWS> <cookie-string>
        || $<name>=["Set-Cookie"]        ':' <.OWS> <set-cookie-string>

        # 7234
        || $<name>=["Cache-Control"]     ':' <.OWS> <Cache-Control>
        || $<name>=["Expires"]           ':' <.OWS> [<Expires> || <.token>]

        # Custom
        || $<name>=["X-XSS-Protection"] ':' <.OWS> [$<status>=<.token> <.OWS> [';' <.OWS> <parameter>?]*] <.OWS>

        # Default header rule
        || $<name>=<.field-name> ':' <.OWS> <field-value> <.OWS>
    }

    token field-name    { <.token> } # the general rule

    token field-value { [<.parameter> || <.field-content> || <.obs-fold>]* }

    token field-content { <.field-vchar> [[<.SP> || <.HTAB> || <.field-vchar>]+ <.field-vchar>]? }

    token field-vchar   { <.VCHAR> || <.obs-text> }

    token last-chunk { 0+ <.chunk-ext>? <.CRLF> }

    token message-body  { <[\x[00]..\x[FF]]>* }
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
    token received-by       { [<.uri-host> [':' <.port>]?] || <.pseudonym>             }
    token received-protocol { [<.protocol-name> '/']? <.protocol-version>              }
    token request-line      { <method> ' ' <request-target> ' ' <HTTP-version> <.CRLF> }
    token request-target    { <.origin-form> || <.absolute-form> || <.authority-form> || <.asterisk-form> }

    token start-line  { <request-line> || <status-line> }
    token status-line { <HTTP-version> <.SP> <status-code> <.SP> <reason-phrase> <.CRLF> }
    token status-code { \d\d\d }


    token t-codings { 'trailers' || [<.transfer-coding> <.t-ranking>?]         }
    token t-ranking { <.OWS> ';' <.OWS> 'q=' <rank>                            }
    token tchar { <+[-!#$%&'*+.^_`|~"] +DIGIT +ALPHA -delimiters -DQUOTE> }
    token token { <.tchar>+ }
    token trailer-part { [<.header-field> <.CRLF>]* }
    token transfer-coding { 
        || 'chunked'
        || 'compress'
        || 'deflate'
        || 'gzip'
        || <.transfer-extension>
    }
    token transfer-extension { <.token> [<.OWS> ';' <.OWS> <.transfer-parameter>]*       }
    token transfer-parameter { <.token> <.BWS> '=' <.BWS> [<.token> || <.quoted-string>] }
}


grammar Zef::Grammars::HTTP::RFC7230 does Zef::Grammars::HTTP::RFC7230::Core {
    token TOP { <HTTP-message> }
}