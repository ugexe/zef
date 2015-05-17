use v6;
# Uniform Resource Identifier (URI): Generic Syntax
# +Representing IPv6 Zone Identifiers in Address Literals and Uniform Resource Identifiers
use Zef::Grammars::HTTP::RFC4234;

role Zef::Grammars::HTTP::RFC3986::Core does Zef::Grammars::HTTP::RFC4234::Core {
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

grammar Zef::Grammars::HTTP::RFC3986 does Zef::Grammars::HTTP::RFC3986::Core {
    token TOP      { <URI-reference> }
    token TOP_URI  { <URI>           }
}