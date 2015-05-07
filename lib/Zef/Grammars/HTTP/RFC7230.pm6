use v6;
# HTTP/1.1 Message Syntax and Routing

use Zef::Grammars::HTTP::RFC4234;
use Zef::Grammars::HTTP::RFC7231;

role Zef::Grammars::HTTP::RFC7230::Core is Zef::Grammars::HTTP::RFC7231::Core {
    also does Zef::Grammars::HTTP::RFC4234::Core;

    # Modified to allow no body (no ending crlf or message-body)
    token HTTP-message { <start-line> [<header-field> [<.CRLF> | $]]* [<.CRLF> <message-body>]? }

    token OWS   { <[\x[20]\x[09]]>* }
    token RWS   { <[\x[20]\x[09]]>+ }

    # fields
    token Connection        { 
        [',' <.RWS>]* <connection-option> [<.RWS> ',' [<.space> <connection-option>]?]* 
    }
    token Content-Length    { [0..9]+ }
    token HTTP-version      { <HTTP-name> '/' $<major>=[\d] '.' $<minor>=[\d] }
    token HTTP-name         { [:!i 'HTTP'] }
    token Host              { <.uri-host> [':' <.port>]? }
    token TE                { [ [',' | <t-codings>] [<.OWS> ',' [<.OWS> <t-codings>]?]*]?     }
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

    # tokens
    token absolute-form  { <.absolute-URI>   }
    token absolute-path  { ['/' <.segment>]+ }
    token asterisk-form  { '*'               }
    token authority-form { <.authority>      }

    token chunk             { <.chunk-size> <.chunk-ext>? <.CRLF> <.chunk-data> <.CRLF> }
    token chunk-data        { <.OCTET>+                                                 }
    token chunk-ext         { [';' <.chunk-ext-name> ['=' <.chunk-ext-val>]?]*          }
    token chunk-ext-name    { <.token>                                                  }
    token chunk-ext-val     { <.token> | <.quoted-string>                               }
    token chunk-size        { <.xdigit>+                                                }
    token chunked-body      { <.chunk>* <.last-chunk> <.trailer-part> <.CRLF>           }
    token comment           { '(' [<.ctext> | <.quoted-pair> | <.comment>]? ')'         }
    token connection-option { <.token> }
    token ctext { 
        <.OWS> | <[\x[21]..\x[27]]> | <[\x[2A]..\x[5B]]> | <[\x[5D]..\x[7E]]> | <.obs-text> 
    }

    token delimiters { <[\"\(\)\,\/\:\;\<\=\>\?\@\[\\\]\{\}]>+ }

    token field-content { <.field-vchar> [<.RWS> <.field-vchar>]?    }
    token field-name    { <.token>                                   }
    token field-value   { [<.field-content> | <.obs-fold>]*          }
    token field-vchar   { <+VCHAR -[,]> | <.obs-text>                }

    # deviates from RFC BNF by handling multiple comma separated column values
    # that the text mentions as intended functionality. unsure if this meant 
    # for specific headers and the BNF was meant for other generic headers.
    token header-field  { 
        $<name>=<.field-name> 
        ':' 
        <.OWS> 
        $<value>=<.field-value> [',' [<.OWS> $<value>=<.field-value>]]* 
        <.OWS>
    }

    token last-chunk { 0+ <.chunk-ext>? <.CRLF> }

    token message-body  { <[\x[00]..\x[FF]]>* }
    token method        { GET | HEAD | POST | PUT | DELETE | CONNECT | OPTIONS | TRACE }

    token obs-fold      { <.CRLF> <.RWS>       }
    token obs-text      { <[\x[80]..\x[FF]]> }
    token origin-form   { <.absolute-path> [ '?' <.query> ]? }
    
    token protocol         { <.protocol-name> ['/' <.protocol-version>]? }
    token protocol-name    { <.token> }
    token protocol-version { <.token> }
    token pseudonym        { <.token> }

    token quoted-string { \x[22] [<.qdtext> | <.quoted-pair>]* \x[22] }
    token quoted-pair   { \\ [<.OWS> | <[\x[21]..\x[7E]]> | <[\x[5D]..\x[7E]]> | <.obs-text>]      }
    token qdtext        { <.OWS> | \x[21] | <[\x[23]..\x[5B]]> | <[\x[5D]..\x[7E]]> | <.obs-text>  }

    token rank              { [0 ['.' \d\d?\d?]?] | [1 ['.' 0?0?]?] }
    token reason-phrase     { [<.RWS> | <.VCHAR> | <.obs-text>]* } 
    token received-by       { [<.uri-host> [':' <.port>]?] | <.pseudonym>  }
    token received-protocol { [<.protocol-name> '/']? <.protocol-version> }
    token request-line      { <method> ' ' <request-target> ' ' <HTTP-version> <.CRLF> }
    token request-target    { <.origin-form> | <.absolute-form> | <.authority-form> | <.asterisk-form> }

    token start-line  { <request-line> | <status-line> }
    token status-line { <HTTP-version> <.SP> <status-code> <.SP> <reason-phrase> <.CRLF> }
    token status-code { \d\d\d }


    token t-codings { 'trailers' | [<.transfer-coding> <.t-ranking>?]          }
    token t-ranking { <.OWS> ';' <.OWS> 'q=' <rank>                            }
    token tchar { <+[-!#$%&'*+.^_`|~] +[a..zA..Z] +[0..9] +VCHAR  -delimiters> }
    token token { <.tchar>+ }
    token trailer-part { [<.header-field> <.CRLF>]* }
    token transfer-coding { 
        | 'chunked'
        | 'compress'
        | 'deflate'
        | 'gzip'
        | <.transfer-extension>
    }
    token transfer-extension { <.token> [<.OWS> ';' <.OWS> <.transfer-parameter>]*       }
    token transfer-parameter { <.token> <.OWS> '=' <.OWS> [<.token> | <.quoted-string>] }
}


grammar Zef::Grammars::HTTP::RFC7230 does Zef::Grammars::HTTP::RFC7230::Core {
    token TOP { <HTTP-message> }
}