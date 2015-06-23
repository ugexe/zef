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
