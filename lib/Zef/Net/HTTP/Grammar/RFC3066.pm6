# Tags for Identification of Languages

role Zef::Net::HTTP::Grammar::RFC3066 {
    token language-tag   { <primary-subtag> ['-' <subtag>]* }
    token primary-subtag { <.ALPHA> ** 1..8                 }
    token subtag         { [<.ALPHA> || <.DIGIT>] ** 1..8   }
}
