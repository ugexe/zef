use v6;
# Hypertext Transfer Protocol (HTTP/1.1): Semantics and Content

use Zef::Grammars::HTTP::RFC4647; 
use Zef::Grammars::HTTP::RFC5646; 
use Zef::Grammars::HTTP::RFC7232; 

role Zef::Grammars::HTTP::RFC7231::Core is Zef::Grammars::HTTP::RFC7232::Core is Zef::Grammars::HTTP::RFC4647::Core {
    also does Zef::Grammars::HTTP::RFC5646::Core;

    token Accept           { [<.OWS> <media-range> <.OWS> [<accept-params> <.OWS>]?] *%% ',' }
    token Accept-Charset   { [<.OWS> [[<charset> || '*'] <weight>?]*] *%% ','                }
    token Accept-Encoding  { [<.OWS> [<codings> <weight>?]*]          *%% ','                }
    token Accept-Language  { [<.OWS> [<language-range> <weight>?]*]   *%% ','                }
    token Allow            { [<.OWS> <method>]                        *%% ','                }
    token Content-Encoding { [<.OWS> <content-coding>]                *%% ','                }
    token Content-Language { [<.OWS> <content-language>]              *%% ','                }
    token Content-Location {
        <absolute-URI> || <partial-URI>
    }
    token Content-Type  { <media-type>   }
    token Date          { <HTTP-date>    }
    token Expect        { '100-continue' }
    token From          { <mailbox>      }
    token GMT           { [:!i GMT]      }
    token HTTP-date     { <IMF-fixdate> || <obs-date> }
    token IMF-fixdate   { <day-name> ',' <.SP> <date1> <.SP> <time-of-day> <.SP> <GMT> }
    token Location      { <URI-reference> }
    token Max-Forwards  { [0..9] }
    token Referer       { <absolute-URI> || <partial-URI> }
    token Retry-After   { <HTTP-date> || <delay-seconds>  }
    token Server        { <product> [<.RWS> [<product> || <comment>]]* }
    token User-Agent    { <product> [<.RWS> [<product> || <comment>]]* }
    token Vary { 
        || '*' 
        || [<.OWS> <field-name>] *%% ','
    }

    token accept-ext    { <.OWS> ';' <.OWS> <.token> ['=' [<.token> || <.quoted-string>]]? }
    token accept-params { <weight> <accept-ext>* }
    token asctime-date  { <day-name> <.SP> <date3> <.SP> <time-of-day> <.SP> <year> }

    token charset { <.token> }
    token codings { <.content-coding> || 'identity' || '*' }
    token content-coding { <.token> }

    token date1 { <day> <.SP> <month> <.SP> <year>   }
    token date2 { <day> '-' <month> '-' $<year>=(\d\d)       }
    token date3 { <month> <.SP> [(\d\d) || (<.SP>\d)] }
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
        || '*/*' 
        || [<type> '/*'] 
        || [<type> '/' <subtype>]
        ]
        [
        [<.OWS> ';'] [[[<.OWS> <parameter>]*] *%% ';']
        ]?
    }

     token media-type { <type> '/' <subtype> [<.OWS> ';' <.OWS> <parameter>]* }
     token method     { <.token> }
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

    token parameter       { $<name>=<.token> '=' $<value>=[<.token> || <.quoted-string>]? }
    token product         { <.token> ['/' <product-version>]? }
    token product-version { <.token> }

    token qvalue { 
        || [0 ['.' \d?\d?\d?]?] 
        || [1 ['.' 0?0?0?]?]
    }

    token rfc850-date { <day-name1> ',' <.SP> <date2> <.SP> <time-of-day> <.SP> <.GMT> }
    token second      { \d\d }
    token subtype     { <.token>}
    token time-of-day { <hour> ':' <minute> ':' <second> }
    token type        { <.token> }
    token weight      { <.OWS> ';' <.OWS> 'q=' <qvalue> }
    token year        { \d\d\d\d }
} 


grammar Zef::Grammars::HTTP::RFC7231 is Zef::Grammars::HTTP::RFC7231::Core {
    # todo
    token TOP {
        <Accept> 
    }
}