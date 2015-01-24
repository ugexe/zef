use v6;
use Zef::Getter;
plan 22;
use Test;


# (5) test default getter
{
    BEGIN my $save-to = $*SPEC.catdir($*CWD, "{time}");    
    UNDO { try { shell("rm -rf $save-to") } if $save-to.IO.e };

    my $getter;
    lives_ok { $getter = Zef::Getter.new }, "Created getter";
    is $getter.plugins.elems, 0, 'no plugins loaded';

    # todo: nearly empty module for testing 
    ok $getter.get(:$save-to, "DB::ORM::Quicky"), 'Used default .get method';
    ok $save-to.IO.e, 'Modules were fetched';
    is shell("rm -rf $save-to").exit, 0, 'deleted test modules';
}

# (8) Plugin::Git
{
    BEGIN my $save-to = $*SPEC.catdir($*CWD, "{time}");    
    UNDO { try { shell("rm -rf $save-to") } if $save-to.IO.e };

    lives_ok { use Zef::Plugin::Git; }, 'Zef::Plugin::Git `use`-able to test with';

    my $getter;
    lives_ok { $getter = Zef::Getter.new(:plugins(["Zef::Plugin::Git"])) }, "Created getter";
    is $getter.plugins.elems, 1, 'one plugin loaded';

    ok $getter.does(::('Zef::Phase::Getting')), 'Zef::Tester has Zef::Phase::Testing applied';
    ok $getter.can('get'), 'Plugin::Git can get()';

    ok $getter.get(:$save-to, 'https://github.com/ugexe/zef'), 'Used Git plugin .get method';
    ok $save-to.IO.e, 'Repo was created';

    is shell("rm -rf $save-to").exit, 0, 'deleted test repo';
}

# (9) Plugin::UA (HTTP::UserAgent)
{
    BEGIN my $save-to = $*SPEC.catpath('', $*SPEC.catdir($*CWD, "{time}"),'zef-get-plugin-ua.zip');    
    UNDO { try { $save-to.IO.unlink } if $save-to.IO.e };

    lives_ok { use Zef::Plugin::UA; }, 'Zef::Plugin::UA `use`-able to test with';

    # github forces ssl?
    lives_ok { require IO::Socket::SSL; }, 'IO::Socket::SSL available';

    my $getter;
    lives_ok { $getter = Zef::Getter.new(:plugins(["Zef::Plugin::UA"])) }, "Created getter";
    is $getter.plugins.elems, 1, 'one plugin loaded';

    ok $getter.does(::('Zef::Phase::Getting')), 'Zef::Getter has Zef::Phase::Getting applied';
    ok $getter.can('get'), 'Zef::Getter can get()';

    lives_ok { 
        $getter.get(:$save-to, 'https://github.com/ugexe/zef/archive/master.zip');
    }, 'Used HTTP::UserAgent plugin .get method';  

    ok $save-to.IO.e, 'Module archive exists';
    ok $save-to.IO.unlink, 'Module archive delete';
}


done();