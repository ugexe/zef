use v6;
use Zef::Getter;
plan 14;
use Test;


# Basic tests on the base class
my $getter = Zef::Getter.new;
is $getter.plugins.elems, 0, 'no plugins loaded';


# Plugin::Git
{
    lives_ok { use Zef::Plugin::Git; }, 'Zef::Plugin::Git `use`-able to test with';
    temp $getter = Zef::Getter.new(:plugins(["Zef::Plugin::Git"])) does Clone;

    ok $getter.does(::('Zef::Phase::Getting')), 'Zef::Tester has Zef::Phase::Testing applied';
    ok $getter.can('get'), 'Zef::Getter can get()';
    

    my $file = $*SPEC.catdir($*CWD, 'zef-get-plugin-git');
    ok $getter.get('https://github.com/ugexe/zef', $file), 'Used Git plugin .get method';
    ok $file.IO.e, 'Repo was created';

    is shell("rm -rf $file").exit, 0, 'deleted test repo';
}

# Plugin::UA (HTTP::UserAgent)
{
    lives_ok { use Zef::Plugin::UA; }, 'Zef::Plugin::UA `use`-able to test with';

    # github forces ssl?
    lives_ok { require IO::Socket::SSL; }, 'IO::Socket::SSL available';

    temp $getter = Zef::Getter.new(:plugins(["Zef::Plugin::UA"]));

    ok $getter.does(::('Zef::Phase::Getting')), 'Zef::Getter has Zef::Phase::Getting applied';
    ok $getter.can('get'), 'Zef::Getter can get()';

    my $file = $*SPEC.catpath('', $*CWD, 'zef-get-plugin-ua.zip');

    lives_ok { 
        $getter.get('https://github.com/ugexe/zef/archive/master.zip', $file);
    }, 'Used HTTP::UserAgent plugin .get method';  

    ok $file.IO.e, 'Repo archive was saved';
    ok $file.IO.unlink, 'Repo archive deleted';
}

done();