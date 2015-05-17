use v6;
# Matching of Language Tags

use Zef::Grammars::HTTP::RFC3066;

role Zef::Grammars::HTTP::RFC4647::Core is Zef::Grammars::HTTP::RFC3066 {
    token language-range          { <language-tag> || '*'                              }
    token extended-language-range { [<primary-subtag> || '*'] ['-' [<subtag> || '*']]* }
}

grammar Zef::Grammars::HTTP::RFC4647 is Zef::Grammars::HTTP::RFC4647::Core {
    token TOP { <.language-range> }
}