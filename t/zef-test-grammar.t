use v6;
use Test;
plan 1;

use Zef::Test::Grammar;

my $output = q{1..8}
    ~ "\n" ~ q{ok 1 - approved operating system}
    ~ "\n" ~ q{# $^0 is solaris}
    ~ "\n" ~ q{ok 2 - # SKIP no /sys directory}
    ~ "\n" ~ q{ok 3 - # TODO add}
    ~ "\n" ~ q{ok 4}
    ~ "\n" ~ q{ok}
    ~ "\n" ~ q{ok - passed test}
    ~ "\n" ~ q{not ok}
    ~ "\n" ~ q{not ok - failed test}
    ~ "\n";

my $parser;

lives-ok { $parser = Zef::Test::Grammar.parse($output) }


done();