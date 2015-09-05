use v6;
use Test;
plan 46;

use Zef::Test::Grammar;

my $output = q{1..8}
    ~ "\n" ~ q{ok 1 - approved operating system}
    ~ "\n" ~ q{# $^0 is ~solaris}
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

is ~$tap.<line>.[0],           "1..8\n";
is ~$tap.<line>.[0].<plan>,    '1..8';
is ~$tap.<line>.[0].<plan>.<start>, 1;
is ~$tap.<line>.[0].<plan>.<end>,   8;

is ~$tap.<line>.[1],                          "ok 1 - approved operating system\n";
is ~$tap.<line>.[1].<test>,                   'ok 1 - approved operating system';
is ~$tap.<line>.[1].<test>.<grade>,           'ok';
is ~$tap.<line>.[1].<test>.<test-number>,     '1';
is ~$tap.<line>.[1].<test>.<why>,             '- approved operating system';

is ~$tap.<line>.[2],                          '# $^0 is ~solaris' ~ "\n";
is ~$tap.<line>.[2].<diagnostics>,            '# $^0 is ~solaris';

is ~$tap.<line>.[3],                          "ok 2 - # SKIP no /sys directory\n";
is ~$tap.<line>.[3].<test>,                   'ok 2 - ';
is ~$tap.<line>.[3].<test>.<grade>,           'ok';
is ~$tap.<line>.[3].<test>.<test-number>,     '2';
is ~$tap.<line>.[3].<test>.<why>,             '- ';
is ~$tap.<line>.[3].<directive>,              "# SKIP no /sys directory";
is ~$tap.<line>.[3].<directive>.<skip>,       'SKIP no /sys directory';
is ~$tap.<line>.[3].<directive>.<skip>.<why>, 'no /sys directory';

is ~$tap.<line>.[4],                          "ok 3 - # TODO add\n";
is ~$tap.<line>.[4].<test>,                   'ok 3 - ';
is ~$tap.<line>.[4].<test>.<grade>,           'ok';
is ~$tap.<line>.[4].<test>.<test-number>,     '3';
is ~$tap.<line>.[4].<test>.<why>,             '- ';
is ~$tap.<line>.[4].<directive>,              "# TODO add";
is ~$tap.<line>.[4].<directive>.<todo>,       'TODO add';
is ~$tap.<line>.[4].<directive>.<todo>.<why>, 'add';

is ~$tap.<line>.[5],                          "ok 4\n";
is ~$tap.<line>.[5].<test>,                   'ok 4';
is ~$tap.<line>.[5].<test>.<grade>,           'ok';
is ~$tap.<line>.[5].<test>.<test-number>,     '4';

is ~$tap.<line>.[6],                          "ok\n";
is ~$tap.<line>.[6].<test>,                   'ok';
is ~$tap.<line>.[6].<test>.<grade>,           'ok';
#is ~$tap.<line>.[6].<test>.<test-number>,     '5'; # need actions to determine this

is ~$tap.<line>.[7],                          "ok - passed test\n";
is ~$tap.<line>.[7].<test>,                   'ok - passed test';
is ~$tap.<line>.[7].<test>.<grade>,           'ok';
is ~$tap.<line>.[7].<test>.<why>,             '- passed test';

is ~$tap.<line>.[8],                          "not ok\n";
is ~$tap.<line>.[8].<test>,                   'not ok';
is ~$tap.<line>.[8].<test>.<grade>,           'not ok';

is ~$tap.<line>.[9],                          "not ok - missing dependency\n";
is ~$tap.<line>.[9].<test>,                   'not ok - missing dependency';
is ~$tap.<line>.[9].<test>.<grade>,           'not ok';
is ~$tap.<line>.[9].<test>.<why>,             '- missing dependency';
