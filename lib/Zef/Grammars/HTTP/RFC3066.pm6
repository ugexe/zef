use v6;
# Tags for Identification of Languages

use Zef::Grammars::HTTP::RFC4234;

role Zef::Grammars::HTTP::RFC3066::Core is Zef::Grammars::HTTP::RFC4234::Core {
    token language-tag { <primary-subtag> ['-' <subtag>]* }
    token primary-subtag { <.ALPHA> 1 ** 8 }
    token subtag { [<.ALPHA> | <.DIGIT>] 1 ** 8 }
}

grammar Zef::Grammars::HTTP::RFC3066 is Zef::Grammars::HTTP::RFC3066::Core {
    token TOP { <.language-tag> }
}