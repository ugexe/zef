# HTTP State Management Mechanism

use Zef::Net::HTTP::Grammar::RFC5322;
use Zef::Net::HTTP::Grammar::RFC1035;

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
