use v6;
use Zef::Tester;
plan 1;
use Test;


# Test default tester
subtest {
    my $tester = Zef::Tester.new;

    ok $tester.can('test'), 'Zef::Tester can do default tester method';

    # my @results := $tester.test("t/00-load.t");
    # ok @results[0].<ok>, 'Test passed';
    # fails for loading a second plan
}, 'Default tester';



done();