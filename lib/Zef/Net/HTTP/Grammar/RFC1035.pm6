# DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION

# token subdomain has been modified. could not get it to work otherwise.

role Zef::Net::HTTP::Grammar::RFC1035 {
    token letter      { [a..zA..Z] }
    token digit       { [0..9]     }
    token domain      { <subdomain> || ' '                        }
    token subdomain   { <+alpha +digit>* ['.' <+alpha +digit>+]+  }
    token label       { <.let-dig-hyp>* <.let-dig>+               }
    token let-dig-hyp { <.let-dig>+ '-'                           }
    token let-dig     { <.letter> || <.digit>                     }
}
