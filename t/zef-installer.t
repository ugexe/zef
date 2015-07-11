use v6;
use Zef::Installer;
use Zef::Utils::PathTools;
use Test;
plan 1;


subtest {
    my $save-to := $*TMPDIR.IO.child("{time}{100000.rand.Int}").IO;
    try mkdirs($save-to);

    LEAVE { sleep 1; try rm($save-to, :d, :f, :r) }

    my $installer = Zef::Installer.new;
    my @results   = $installer.install(:$save-to, "META.info");

    ok @results.elems,                                "Got non-zero number of results"; 
    is @results.grep({ $_<ok>.so }).elems,         1, "All modules installed OK";
    is @results.[0].<name>,                    'Zef', "name:Zef matches in pass results";
    ok $save-to.IO.child('MANIFEST').IO.e,            "MANIFEST created";
}, 'Zef can install zef';


done();