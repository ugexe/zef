use v6;
use Test;
plan 46;

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
    ~ "\n" ~ q{not ok - missing dependency}
    ~ "\n";

my $tap;

lives-ok { $tap = Zef::Test::Grammar.parse($output) }

is $tap.<line>.[0].Str,           "1..8\n";
is $tap.<line>.[0].<plan>.Str,    '1..8';
is $tap.<line>.[0].<plan>.<start>, 1;
is $tap.<line>.[0].<plan>.<end>,   8;

is $tap.<line>.[1].Str,                          "ok 1 - approved operating system\n";
is $tap.<line>.[1].<test>.Str,                   'ok 1 - approved operating system';
is $tap.<line>.[1].<test>.<grade>.Str,           'ok';
is $tap.<line>.[1].<test>.<test-number>.Str,     '1';
is $tap.<line>.[1].<test>.<why>.Str,             '- approved operating system';

is $tap.<line>.[2].Str,                          '# $^0 is solaris' ~ "\n";
is $tap.<line>.[2].<diagnostics>.Str,            '# $^0 is solaris';

is $tap.<line>.[3].Str,                          "ok 2 - # SKIP no /sys directory\n";
is $tap.<line>.[3].<test>.Str,                   'ok 2 - ';
is $tap.<line>.[3].<test>.<grade>.Str,           'ok';
is $tap.<line>.[3].<test>.<test-number>.Str,     '2';
is $tap.<line>.[3].<test>.<why>.Str,             '- ';
is $tap.<line>.[3].<directive>.Str,              "# SKIP no /sys directory";
is $tap.<line>.[3].<directive>.<skip>.Str,       'SKIP no /sys directory';
is $tap.<line>.[3].<directive>.<skip>.<why>.Str, 'no /sys directory';

is $tap.<line>.[4].Str,                          "ok 3 - # TODO add\n";
is $tap.<line>.[4].<test>.Str,                   'ok 3 - ';
is $tap.<line>.[4].<test>.<grade>.Str,           'ok';
is $tap.<line>.[4].<test>.<test-number>.Str,     '3';
is $tap.<line>.[4].<test>.<why>.Str,             '- ';
is $tap.<line>.[4].<directive>.Str,              "# TODO add";
is $tap.<line>.[4].<directive>.<todo>.Str,       'TODO add';
is $tap.<line>.[4].<directive>.<todo>.<why>.Str, 'add';

is $tap.<line>.[5].Str,                          "ok 4\n";
is $tap.<line>.[5].<test>.Str,                   'ok 4';
is $tap.<line>.[5].<test>.<grade>.Str,           'ok';
is $tap.<line>.[5].<test>.<test-number>.Str,     '4';

is $tap.<line>.[6].Str,                          "ok\n";
is $tap.<line>.[6].<test>.Str,                   'ok';
is $tap.<line>.[6].<test>.<grade>.Str,           'ok';
#is $tap.<line>.[6].<test>.<test-number>.Str,     '5'; # need actions to determine this

is $tap.<line>.[7].Str,                          "ok - passed test\n";
is $tap.<line>.[7].<test>.Str,                   'ok - passed test';
is $tap.<line>.[7].<test>.<grade>.Str,           'ok';
is $tap.<line>.[7].<test>.<why>.Str,             '- passed test';

is $tap.<line>.[8].Str,                          "not ok\n";
is $tap.<line>.[8].<test>.Str,                   'not ok';
is $tap.<line>.[8].<test>.<grade>.Str,           'not ok';

is $tap.<line>.[9].Str,                          "not ok - missing dependency\n";
is $tap.<line>.[9].<test>.Str,                   'not ok - missing dependency';
is $tap.<line>.[9].<test>.<grade>.Str,           'not ok';
is $tap.<line>.[9].<test>.<why>.Str,             '- missing dependency';
