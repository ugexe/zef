use v6;
use Zef::Tester;
plan 4;
use Test;

# Basic tests on the base class
my $tester;
lives_ok { $tester = Zef::Tester.new; }

# Test default tester
{
    temp $tester = Zef::Tester.new;

    ok $tester.can('test'), 'Zef::Tester can do default tester method';

    # fails for loading a second plan
    # ok $tester.test("t/00-load.t"), 'passed basic test using perl6 shell command';
}

# Test another tester: Plugin::P5Prove
{
    lives_ok { require Zef::Plugin::P5Prove; }, 'Zef::Plugin::P5Prove `use`-able to test with';
    temp $tester = Zef::Tester.new( :plugins(["Zef::Plugin::P5Prove"]) );

    ok $tester.does(::('Zef::Phase::Testing')), 'Zef::Tester has Zef::Phase::Testing applied';
    
    # Passes, but technically fails. Test.pm6 or TAP::Harness get confused on plan count
    # ok $tester.test("t/00-load.t"), 'passed basic test using `prove` shell command (exit code 0)';
}


# todo: mock loading P5Prove from config file?
{
#    ...
}

done();