use v6;
use Zef::Builder;
plan 2;
use Test;


# Basic tests on the base class
{
    lives_ok { use Zef::Plugin::PreComp; }, 'Zef::Plugin::PreComp `use`-able to test with';
    my $builder = Zef::Builder.new(:plugins(["Zef::Plugin::PreComp"]));

    ok $builder.does(::('Zef::Phase::Building')), 'Zef::Builder has Zef::Phase::Building applied';
}

done();