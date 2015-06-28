use v6;
use Zef::Installer;
use Zef::Utils::PathTools;
use Test;
plan 1;


subtest {
    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    ENTER {
        try mkdirs($save-to);
        sleep 1;
    }
    LEAVE {       # Cleanup
        sleep 1;  # bug-fix for CompUnit related pipe file race
        try rm($save-to, :d, :f, :r);
    }

    my @results = Zef::Installer.new.install(:$save-to, "META.info");

    ok @results.elems,                                "Got non-zero number of results"; 
    is all(@results>>.EXISTS-KEY("ok")),        True, "All modules were marked pass/fail";
    is all(@results>>.AT-KEY("ok")),               1, "All modules installed OK";
    is any(@results>>.AT-KEY("name")),         'Zef', "name:Zef matches in pass results";
    ok $*SPEC.catpath('', $save-to, 'MANIFEST').IO.e, "MANIFEST created";
}, 'Zef can install zef';


done();