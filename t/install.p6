use v6;
use Test;
plan 1;
use Zef;

is( Zef->install(auth => '*', version => '*', unit => 'Text::Levenshtein::Damerau'), 1, 'Just install a module!');