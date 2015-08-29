use v6;
use Zef::Distribution::Local;
use Zef::Roles::Installing;
use Zef::Utils::PathTools;
use Zef::Manifest;
use Test;
plan 2;

my $path        := $?FILE.IO.dirname.IO.parent; # ehhh
my $install-to  := $path.child("test-libs_{time}{100000.rand.Int}").IO;
my $distribution = Zef::Distribution::Local.new(:$path, :precomp-path($install-to));
try mkdirs($install-to);
LEAVE { sleep 1; try rm($install-to, :d, :f, :r) }


subtest {
    $distribution does Zef::Roles::Installing[$install-to];

    my @source-files = $distribution.provides(:absolute).values;
    my $results      = $distribution.install(:force);

    ok $results.list.elems,                        "Got non-zero number of results"; 
    is $results.list.grep({ $_<ok>.so }).elems, 1, "All modules installed OK";
    is $results.list.[0].hash.<name>,       'Zef', "name:Zef matches in pass results";
    ok $install-to.IO.child('MANIFEST').IO.e,      "MANIFEST exists";
}, 'Zef can install zef';


# need to be tested together so tests can be run out of order
subtest {
    my $manifest;
    lives-ok { $manifest = Zef::Manifest.new(:cur($install-to)) };
    ok $manifest.uninstall($distribution), 'Uninstall did not fail'; 
    is $manifest.file-count, 0, 'MANIFEST file-count: 0';
    is $manifest.dist-count, 0, 'MANIFEST dist-count: 0'
}, 'Zef can uninstall zef';
