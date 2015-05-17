use v6;
# Hypertext Transfer Protocol (HTTP/1.1): Range Requests

use Zef::Grammars::HTTP::RFC7234;

role Zef::Grammars::HTTP::RFC7233::Core is Zef::Grammars::HTTP::RFC7234::Core {
    token Accept-Ranges { <acceptable-ranges> }
    token Content-Range { <.byte-content-range> || <.other-content-range> }

    # token HTTP-date 7231
    token If-Range { <.entity-tag> || <.HTTP-date> }

    # token OWS 7230
    token Range { <.byte-ranges-specifier> || <.other-ranges-specifier> }
    token acceptable-ranges {  
        [
        || [[',' <.OWS>]* <.range-unit> [<.OWS> ',' [<.OWS> <.range-unit>]]*]
        || 'none'
        ]
    }

    token byte-content-range { <.bytes-unit> <.SP> [<.byte-range-resp> || <.unsatisfied-range>] }
    token byte-range         { <.first-byte-pos> '-' <.last-byte-pos>                           }
    token byte-range-resp    { <.byte-range> '/' [<.complete-length> || '*']                    }

    token byte-range-set { 
        [',' <.OWS>]* 

        [
        ||  <.byte-range-spec> 
        ||  <.suffix-byte-range-spec>
        ]

        [
        <.OWS> ','
            [
            <.OWS> 
            [
            || <.byte-range-spec>
            || <.suffix-byte-range-spec>
            ]?
            ]
        ]*
    }

    token byte-range-spec       { <.first-byte-pos> '-' <.last-byte-pos>? }
    token byte-ranges-specifier { <.bytes-unit> '=' <.byte-range-set>     }
    token bytes-unit            { 'bytes'   }
    token complete-length       { <.DIGIT>+ }

    # token entity-tag  7232
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


grammar Zef::Grammars::HTTP::RFC7233 is  Zef::Grammars::HTTP::RFC7233::Core {
    # todo
    token TOP {
        <Content-Range> 
    }
}
