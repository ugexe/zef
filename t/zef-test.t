use v6;
use Zef::Test;
use Test;
plan 1;


# Test default tester
subtest {
    my $tester = Zef::Test.new(path => $?FILE.IO.dirname.IO.dirname);

    ok $tester.can('test'), 'Zef::Tester can do default tester method';

    # my @results := $tester.test("t/00-load.t");
    # ok @results[0].<ok>, 'Test passed';
    # fails for loading a second plan
}, 'Default tester';



done();