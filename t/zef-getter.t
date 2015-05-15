use v6;
use Zef::Getter;
use Zef::Utils::PathTools;
plan 2;
use Test;


subtest {
    ENTER {
        try { IO::Socket::INET.new(:host<zef.pm>, :port(80)) } or do {
            print("ok - # Skip: No internet connection available? http://zef.pm:80\n");
            return;
        }
    }

    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdirs($save-to);
    LEAVE try rm($save-to, :d, :f, :r);

    ok my $getter = Zef::Getter.new;

    # todo: nearly empty module for testing
    #my @results = $getter.get(:$save-to, "DB::ORM::Quicky");
    #my @saved   = ls($save-to, :f, :r, d => False);

    #ok $save-to.IO.e, 'Modules were fetched';
    #is @saved.elems, @results.grep({ $_.<ok> }).elems, "OK results according to .install";
    #ok @saved.elems > 3, "Repo file count of '{@saved.elems}' appears valid";    
}, "Default Getter";


subtest {
    ENTER {
        try { shell("{%*ENV<GIT_BINARY> // 'git'} --version").exitcode == 0 } or do {
            print("ok - # Skip: git command not available?\n");
            return;
        }

        try require Zef::Plugin::Git;
        if ::("Zef::Plugin::Git") ~~ Failure {
            print("ok - # Skip: Zef::Plugin::Git not available\n");
            return;
        }

        try { IO::Socket::INET.new(:host<github.com>, :port(80)) } or do {
            print("ok - # Skip: No internet connection available? http://github.com:80\n");
            return;
        }
    }

    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdirs($save-to);
    LEAVE try rm($save-to, :d, :f, :r);


    my $getter = Zef::Getter.new( :plugins(['Zef::Plugin::Git']) );

    ok $getter.get(:$save-to, 'https://github.com/ugexe/zef'), 'Used Git plugin .get method';
    my @saved = ls($save-to.IO.path, :f, :r);
    ok @saved.elems > 3, "Repo was created: {@saved.elems}";

}, 'Zef::Plugin::Git';


done();