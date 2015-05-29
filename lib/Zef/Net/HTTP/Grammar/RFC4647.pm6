# Matching of Language Tags

role Zef::Net::HTTP::Grammar::RFC4647 {
    token language-range          { <language-tag> || '*'                              }
    token extended-language-range { [<primary-subtag> || '*'] ['-' [<subtag> || '*']]* }
}
