use v6;
use Zef::Getter;
plan 3;
use Test;

my $save-to = $*CWD ~ '/testing';


subtest {
    temp $save-to = $*SPEC.catdir($save-to.IO.dirname, ~time);    
    LEAVE try { shell("rm -rf $save-to") }

    my $getter;
    lives_ok { $getter = Zef::Getter.new }, "Created getter";

    # todo: nearly empty module for testing 
    my $x = $getter.get(:$save-to, "DB::ORM::Quicky");

    ok $x, 'Used default .get method';
    ok $save-to.IO.e, 'Modules were fetched';
}, "Default Getter";


subtest {
    temp $save-to = $*SPEC.catdir($save-to.IO.dirname, ~time);    
    # TODO: replace this with something sane
    LEAVE { shell("rm -rf $save-to"); }

    lives_ok { use Zef::Plugin::Git; }, 'Zef::Plugin::Git `use`-able to test with';

    my $getter;
    lives_ok { $getter = Zef::Getter.new( :plugins(['Zef::Plugin::Git'])) }, "Created getter";

    ok $getter.does(::('Zef::Phase::Getting')), 'Zef::Tester has Zef::Phase::Testing applied';
    ok $getter.can('get'), 'Plugin::Git can get()';

    ok $getter.get(:$save-to, 'https://github.com/ugexe/zef'), 'Used Git plugin .get method';
    ok $save-to.IO.e, 'Repo was created';

}, 'Plugin::Git';


subtest {
    ENTER {
        try { require HTTP::UserAgent } or do {
            print("ok 3 - # Skip: HTTP::UserAgent not available\n");
            return;
        };
    }


    temp $save-to = $*SPEC.catpath('', $*SPEC.catdir($save-to.IO.dirname, ~time),'zef-get-plugin-ua.zip');    
    # TODO: replace this with something sane
    LEAVE { shell("rm -rf {$save-to.IO.dirname}"); }
    try { mkdir $save-to.IO.dirname } or fail "Failed to create save-to directory";

    lives_ok { use Zef::Plugin::UA; }, 'Zef::Plugin::UA `use`-able to test with';

    # github forces ssl
    lives_ok { require IO::Socket::SSL; }, 'IO::Socket::SSL available';

    my $getter;
    lives_ok { $getter = Zef::Getter.new(:plugins(["Zef::Plugin::UA"])) }, "Created getter";

    ok $getter.does(::('Zef::Phase::Getting')), 'Zef::Getter has Zef::Phase::Getting applied';
    ok $getter.can('get'), 'Zef::Getter can get()';

    # TODO: HTTP::UserAgent PR for binary encoding of certain files
    #lives_ok { 
    #    $getter.get(:$save-to, 'https://github.com/ugexe/zef/archive/master.zip');
    #}, 'Used HTTP::UserAgent plugin .get method';  
    #
    #ok $save-to.IO.e, 'Module archive exists';
}, 'Plugin::UA';


done();