use v6;
use Zef::Installer;
use Zef::Utils::PathTools;
plan 1;
use Test;


subtest {
    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdirs($save-to);
    LEAVE rm($save-to, :d, :f, :r);

    my @results = Zef::Installer.new.install(:$save-to, "META.info");

    ok @results.elems,                                "Got non-zero number of results"; 
    is all(@results>>.EXISTS-KEY("pass")), True,      "All modules were marked pass/fail";
    is all(@results>>.AT-KEY("pass")),        1,      "All modules installed OK";
    is any(@results>>.AT-KEY("name")),    "Zef",      "name:Zef matches in pass results";
    ok $*SPEC.catpath('', $save-to, 'MANIFEST').IO.e, "MANIFEST created";
}, 'Zef can install zef';


done();