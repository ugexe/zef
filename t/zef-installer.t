use v6;
use Zef::Distribution;
use Zef::Roles::Installing;
use Zef::Utils::PathTools;
use Test;
plan 1;


subtest {
    my $path         := $?FILE.IO.dirname.IO.parent; # ehhh
    my $install-to   := $path.child("test-libs_{time}{100000.rand.Int}").IO;

    try mkdirs($install-to);
    LEAVE { sleep 1; try rm($install-to, :d, :f, :r) }

    my $distribution = Zef::Distribution.new(:$path, :precomp-path($install-to));
    $distribution does Zef::Roles::Installing[$install-to];

    my @source-files = $distribution.provides(:absolute).values;
    my $results      = $distribution.install(:force);

    ok $results.list.elems,                        "Got non-zero number of results"; 
    is $results.list.grep({ $_<ok>.so }).elems, 1, "All modules installed OK";
    is $results.list.[0].hash.<name>,       'Zef', "name:Zef matches in pass results";
    ok $install-to.IO.child('MANIFEST').IO.e,      "MANIFEST exists";
}, 'Zef can install zef';
