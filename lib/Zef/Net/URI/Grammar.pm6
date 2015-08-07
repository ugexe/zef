# Uniform Resource Identifier (URI): Generic Syntax
# +Representing IPv6 Zone Identifiers in Address Literals and Uniform Resource Identifiers
role Zef::Net::URI::Grammar::RFC3986 {
    token URI-reference { <URI> || <relative-ref>                                   }
    token URI           { <scheme> ':' <heir-part> ['?' <query>]? ['#' <fragment>]? }
    token absolute-URI  { <scheme> : <heir-part> ['?' <query>]?                     }
    token relative-ref  { <relative-part> ['?' <query>]? ['#' <fragment>]?          }
    token heir-part     { 
        || '//' <authority> <path-abempty> 
        || <path-absolute> 
        || <path-noscheme> 
        || <path-empty> 
    }
    token relative-part { 
        || '//' <authority> <path-abempty> 
        || <path-absolute> 
        || <path-noscheme> 
        || <path-empty> 
    }

    token scheme { 
        <.ALPHA> 
        [
        || <.ALPHA>
        || <.DIGIT>
        || '+'
        || '-'
        || '.'
        ]*
    }

    token authority   { [<userinfo> '@']? <host> [':' <port>]? }
    token userinfo    { [<.unreserved> || <.pct-encoded> || <.sub-delims> || ':']*  }
    token host        { <.IP-literal> || <.IPv4address> || <.reg-name>              }
    token IP-literal  { '[' [<.IPv6address> || <.IPv6addrz> || <.IPvFuture>] ']'    }
    token IPv6addz    { <.IPv6address> '%25' <.ZoneID>    }
    token ZoneID      { [<.unreserved> || <.pct-encoded>]+ }
    token IPvFuture   { 'v' <.HEXDIG>+ '.' [<.unreserved> || <.sub-delims> || ':']+ }
    token IPv6address {
        ||                                      [<.h16>   ':'] ** 6 <.ls32>
        ||                                 '::' [<.h16>   ':'] ** 5 <.ls32>
        || [ <.h16>                     ]? '::' [<.h16>   ':'] ** 4 <.ls32>
        || [[<.h16> ':'] ** 0..1 <.h16> ]? '::' [<.h16>   ':'] ** 3 <.ls32>
        || [[<.h16> ':'] ** 0..2 <.h16> ]? '::' [<.h16>   ':'] ** 2 <.ls32>
        || [[<.h16> ':'] ** 0..3 <.h16> ]? '::'  <.h16>   ':'       <.ls32>
        || [[<.h16> ':'] ** 0..4 <.h16> ]? '::'                     <.ls32>
        || [[<.h16> ':'] ** 0..5 <.h16> ]? '::'  <.h16>
        || [[<.h16> ':'] ** 0..6 <.h16> ]? '::'
    }
    token h16  { <.HEXDIG> ** 1..4 }
    token ls32 { [<.h16> ':' <.h16>] || <.IPv4address> }
    token IPv4address { <.dec-octet> '.' <.dec-octet> '.' <.dec-octet> '.' <.decoctet> }
    token dec-octet {
        || <.DIGIT>
        || [\x[31]..\x[39]] <.DIGIT>
        || '1' <.DIGIT> ** 2
        || '2'  [\x[30]..\x[34]] <.DIGIT>
        || '25' [\x[30]..\x[35]]
    }
    token reg-name { [<.unreserved> || <.pct-encoded> || <.sub-delims>]* }
    token port     { <.DIGIT>* }

    token path     { 
        || <.path-abempty>
        || <.path-absolute>
        || <.path-noscheme>
        || <.path-rootless>
        || <.path-empty>
    }
    token path-abempty  { ['/' <.segment>]*                      }
    token path-absolute { '/' [<.segment-nz> ['/' <.segment>]*]? }
    token path-noscheme { <.segment-nz-nc> ['/' <.segment>]*     }
    token path-rootless { <.segment-nz> ['/' <.segment>]*        }
    token path-empty    { <.pchar> ** 0                          }
    token segment       { <.pchar>* }
    token segment-nz    { <.pchar>+ }
    token segment-nz-nc { [<.unreserved> || <.pct-encoded> || <.sub-delims>]+    }
    token pchar { <.unreserved> || <.pct-encoded> || <.sub-delims> || ':' || '@' }
    token query       { [<.pchar> || '/' || '?']*           }
    token fragment    { [<.pchar> || '/' || '?']*           }
    token pct-encoded { '%' <.HEXDIG> <.HEXDIG>             }
    token unreserved  { <.ALPHA> || <.DIGIT> || < - . _ ~ > }
    token reserved    { <.gen-delims> || <.sub-delims>      }

    token gen-delims  { < : / ? # [ ] @ >         }
    token sub-delims  { < ! $ & ' ( ) * + , ; = > }
}



role Zef::Net::URI::Grammar::RFC4234 {
    token ALPHA  { <[\x[41]..\x[5A]]> || <[\x[61]..\x[7A]]> }
    token BIT    { 0 || 1                                   }
    token CHAR   { <[\x[01]..\x[7F]]>                       }
    token CR     { \x[0D]                                   }
    token CRLF   { [<.CR> <.LF>]                            }
    token CTL    { <[\x[00]..\x[1F]]> || \x[7F]             }
    token DIGIT  { <[\x[30]..\x[39]]>                       }
    token DQUOTE { \x[22]                                   }
    token HEXDIG { <.DIGIT> || <[a..fA..F]>                 }
    token HTAB   { \x[09]                                   }
    token LF     { \x[0A]                                   }
    token LWSP   { [<.WSP> || <.CRLF> <.WSP>]*              }
    token OCTET  { <[\x[00]..\x[FFFF]]>                     } # modified for 16-bit Unicode
    token SP     { \x[20]                                   }
    token VCHAR  { <[\x[21]..\x[7E]]>                       }
    token WSP    { <.SP> || <.HTAB>                         }

    token rulelist      { [<rule> || [.<c-wsp>* <.c-nl>]]+                              }
    token rule          { <rulename> <defined-as> <elements> <.c-nl>                    }
    token rulename      { <.ALPHA> [<.ALPHA> || <.DIGIT> || '-']*                       }
    token defined-as    { <.c-wsp>* '=' '/'? <.c-wsp>*                                  }
    token elements      { <.alternation> <.c-wsp>*                                      }
    token c-wsp         { <.WSP> || [<c-nl> <.WSP>]                                     }
    token c-nl          { <.comment> || <.CRLF>                                         }
    my token comment       { ';' [<.WSP> || <.VCHAR>]* <.CRLF>                             }
    token alternation   { <.concatenation> [<.c-wsp>* '/' <.c-wsp>* <.concatenation>]*  }
    token concatenation { <.repetition> [<.c-wsp>+ <.repetition>]*                      }
    token repetition    { <.repeat>? <.element>                                         }
    token repeat        { <.DIGIT>+ || [<.DIGIT>* '*' <.DIGIT>*]                        }
    token element {
        || <.rulename>
        || <.group>
        || <.option>
        || <.char-val>
        || <.num-val>
        || <.prose-val>
    }

    token group     { '(' <.c-wsp> <.alternation> <.c-wsp>* ')'                  }
    token option    { '[' <.c-wsp> <.alternation> <.c-wsp>* ']'                  }
    token char-val  { <.DQUOTE> <+[\x[20]..\x[21]] +[\x[23]..\x[7E]]>* <.DQUOTE> }
    token num-val   { '%' [<.bin-val> || <.dec-val> || <.hex-val>]               }
    token bin-val   { 'b' <.BIT>+ [ ['.' <.BIT>+]+ || ['-' <.BIT>+] ]?           }
    token dec-val   { 'd' <.DIGIT>+ [ ['.' <.DIGIT>+]+ || ['-' <.DIGIT>] ]?      }
    token hex-val   { 'x' <.HEXDIG>+ [ ['.' <.HEXDIG>+]+ || ['-' <.HEXDIG>] ]?   }
    token prose-val { '<' <+[\x[20]..\x[3D]] +[\x[3F]..\x[7E]]>* '>'             }
}




grammar Zef::Net::URI::Grammar {
    also does Zef::Net::URI::Grammar::RFC3986;
    also does Zef::Net::URI::Grammar::RFC4234;

    token TOP      { <URI-reference> }
    token TOP_URI  { <URI>           }
}
