use v6;
use Zef::Tester;

use Test;
plan 6;


# Basic tests on the base class
my @plugins;
my $tester = Zef::Tester.new(:@plugins);
is $tester.plugins.elems, 0, 'no plugins loaded';

$tester.plugins.push("Not-Real");
is $tester.plugins.elems, 1, 'can add new plugins';

$tester.plugins.shift;
is $tester.plugins.elems, 0, 'plugins cleared';


# Plugin::P5Prove
{
    lives_ok { use Zef::Plugin::P5Prove; };

    state $tester = Zef::Tester.new(:plugins(["Zef::Plugin::P5Prove"]));
    ok $tester.does(::('Zef::Phase::Testing')), '$tester has Zef::Phase::Testing has applied';

    ok $tester.test("t/00-load.t"), 'passed basic test using `prove` shell command';
}


# todo: mock loading P5Prove from config file?
{
#    ...
}