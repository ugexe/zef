use v6;
# Matching of Language Tags

use Zef::Grammars::HTTP::RFC3066;

grammar Zef::Grammars::HTTP::RFC4647 is Zef::Grammars::HTTP::RFC3066 {
    token TOP { <.language-range> }

    token language-range { <.language-tag> | '*' }
    token extended-language-range { 
        [<primary-subtag> | '*'] ['-' [<subtag> | '*']]*
    }
}
