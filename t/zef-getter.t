use v6;
use Zef::Getter;
use Zef::Utils::FileSystem;
plan 3;
use Test;


subtest {
    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdir($save-to);
    LEAVE Zef::Utils::FileSystem.new( path => $save-to.path ).rm(:d, :f, :r);

    my $getter;
    lives_ok { $getter = Zef::Getter.new }, "Created getter";

    # todo: nearly empty module for testing 
    ok $getter.get(:$save-to, "DB::ORM::Quicky");
    my @saved = Zef::Utils::FileSystem.ls($save-to.path, :f, :r);
    ok $save-to.IO.e, 'Modules were fetched';
    ok @saved.elems > 3, "Repo was created:: {@saved.elems}";    
}, "Default Getter";


subtest {
    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdir($save-to);
    LEAVE Zef::Utils::FileSystem.new( path => $save-to.path ).rm(:d, :f, :r);

    lives_ok { require Zef::Plugin::Git; }, 'Zef::Plugin::Git `use`-able to test with';

    my $getter;
    lives_ok { $getter = Zef::Getter.new( :plugins(['Zef::Plugin::Git']) ) }, "Created getter";

    ok $getter.get(:$save-to, 'https://github.com/ugexe/zef'), 'Used Git plugin .get method';
    my @saved = Zef::Utils::FileSystem.ls($save-to.path, :f, :r);
    ok @saved.elems > 3, "Repo was created: {@saved.elems}";

}, 'Plugin::Git';


subtest {
    ENTER {
        try { require HTTP::UserAgent } or do {
            print("ok 3 - # Skip: HTTP::UserAgent not available\n");
            return;
        };
    }

    my $save-to = $*SPEC.catpath('',$*SPEC.catdir($*TMPDIR, time),'zef-get-plugin-ua.zip').IO;
    try mkdir($save-to.dirname);
    LEAVE Zef::Utils::FileSystem.new( path => $save-to.dirname ).rm(:d, :f, :r);

    lives_ok { use Zef::Plugin::UA; }, 'Zef::Plugin::UA `use`-able to test with';
    # github forces ssl
    lives_ok { require IO::Socket::SSL; }, 'IO::Socket::SSL available';

    my $getter;
    lives_ok { $getter = Zef::Getter.new(:plugins(["Zef::Plugin::UA"])) }, "Created getter";
    # todo: http::useragent patch for binary
    #lives_ok { $getter.get(:$save-to, 'https://github.com/ugexe/zef/archive/master.zip') }
    #ok $save-to.e, "$save-to exists";
    #ok $save-to.f, "$save-to is a file";
}, 'Plugin::UA';


done();