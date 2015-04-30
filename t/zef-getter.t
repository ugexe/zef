use v6;
use Zef::Getter;
use Zef::Utils::FileSystem;
plan 3;
use Test;


subtest {
    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdirs($save-to.IO.path);
    LEAVE try rm($save-to.IO.path, :d, :f, :r);

    my $getter = Zef::Getter.new;

    # todo: nearly empty module for testing
    ok $getter.get(:$save-to, "DB::ORM::Quicky");
    my @saved := ls($save-to.IO.path, :f, :r);
    ok $save-to.IO.e, 'Modules were fetched';
    ok @saved.elems > 3, "Repo file count: {@saved.elems}";    
}, "Default Getter";


subtest {
    ENTER {
        try { shell("{%*ENV<GIT_BINARY> // 'git'} --version").exitcode == 0 } or do {
            print("ok 4 - # Skip: git command not available?\n");
            return;
        };

        try require Zef::Plugin::Git;
        if ::("Zef::Plugin::Git") ~~ Failure {
            print("ok 3 - # Skip: Zef::Plugin::Git not available\n");
            return;
        }
    }

    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdirs($save-to.IO.path);
    LEAVE try rm($save-to.IO.path, :d, :f, :r);

    #lives_ok { require Zef::Plugin::Git; }, 'Zef::Plugin::Git `use`-able to test with';

    my $getter = Zef::Getter.new( :plugins(['Zef::Plugin::Git']) );

    ok $getter.get(:$save-to, 'https://github.com/ugexe/zef'), 'Used Git plugin .get method';
    my @saved = ls($save-to.IO.path, :f, :r);
    ok @saved.elems > 3, "Repo was created: {@saved.elems}";

}, 'Plugin::Git';


subtest {
    ENTER {
        try require HTTP::UserAgent; 
        try require IO::Socket::SSL;
        if ::('IO::Socket::SSL') ~~ Failure {
            print("ok 3 - # Skip: IO::Socket::SSL not available\n");
            return;
        }
        if ::('HTTP::UserAgent') ~~ Failure {
            print("ok 3 - # Skip: HTTP::UserAgent not available\n");
            return;
        }
    }

    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdirs($save-to.IO.path);
    my $save-to-file =$*SPEC.catpath('', $save-to, 'zef-get-plugin-ua.zip').IO;
    LEAVE try rm($save-to.IO.path, :d, :f, :r);

    lives_ok { use Zef::Plugin::UA; }, 'Zef::Plugin::UA `use`-able to test with';

    my $getter = Zef::Getter.new( :plugins(["Zef::Plugin::UA"]) );

    ok $getter.does("Zef::Plugin::UA");
    # todo: http::useragent patch for binary
    #lives_ok { $getter.get(:$save-to-file, 'https://github.com/ugexe/zef/archive/master.zip') }
    #ok $save-to-file.e, "$save-to exists";
    #ok $save-to-file.f, "$save-to is a file";
}, 'Plugin::UA';


done();