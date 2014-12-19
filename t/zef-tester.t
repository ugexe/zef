use v6;
use Zef::Tester;
plan 7;
use Test;


# Basic tests on the base class
my $tester = Zef::Tester.new;
is $tester.plugins.elems, 0, 'no plugins loaded';

$tester.plugins.push("Not-Real");
is $tester.plugins.elems, 1, 'can add new plugins';

# more of an example of plugin passing than actual test
{
    my @plugins;
    is Zef::Tester.new(:@plugins).plugins.elems, 0, 'no plugins to be loaded';

    @plugins = <Zef::Plugin::P5Prove>;
    is Zef::Tester.new(:@plugins).plugins.elems, 1, 'added a plugin'
}

$tester.plugins.shift;
is $tester.plugins.elems, 0, 'plugins cleared';


# Plugin::P5Prove
{
    # Plugins should have their own unit tests, but until a more appropriate default
    # is added we need a plugin to actually test Zef::Tester 
    lives_ok { use Zef::Plugin::P5Prove; }, 'Zef::Plugin::P5Prove `use`-able to test with';
    temp $tester = Zef::Tester.new(:plugins(["Zef::Plugin::P5Prove"]));

    ok $tester.does(::('Zef::Phase::Testing')), 'Zef::Tester has Zef::Phase::Testing applied';
    
    # Passes, but technically fails. Test.pm6 or TAP::Harness get confused on plan count
    # ok $tester.test("t/00-load.t"), 'passed basic test using `prove` shell command (exit code 0)';
}


# todo: mock loading P5Prove from config file?
{
#    ...
}

done();