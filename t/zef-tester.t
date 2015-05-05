use v6;
use Zef::Tester;
plan 2;
use Test;


# Test default tester
subtest {
    my $tester = Zef::Tester.new;

    ok $tester.can('test'), 'Zef::Tester can do default tester method';

    # my @results := $tester.test("t/00-load.t");
    # ok @results[0].<ok>, 'Test passed';
    # fails for loading a second plan
}, 'Default tester';


# Test another tester: Plugin::P5Prove
subtest {
    ENTER {
        try require Zef::Plugin::P5Prove;
        if ::('Zef::Plugin::P5Prove') {
            print("ok - # Skip: Zef::Plugin::P5Prove not available\n");
            return;
        }
    }
    
    my $tester = Zef::Tester.new( :plugins(["Zef::Plugin::P5Prove"]) );

    ok $tester.does(::('Zef::Phase::Testing')), 'Zef::Tester has Zef::Phase::Testing applied';
    
    # Passes, but technically fails. Test.pm6 or TAP::Harness get confused on plan count
    # ok $tester.test("t/00-load.t"), 'passed basic test using `prove` shell command (exit code 0)';
}, 'Zef::Plugin::P5Prove';



done();