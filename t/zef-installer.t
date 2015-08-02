use v6;
use Zef::Distribution;
use Zef::Roles::Installing;
use Zef::Utils::PathTools;
use Test;
plan 1;


subtest {
    my $path         := $?FILE.IO.dirname.IO.parent; # ehhh
    my $precomp-path := $path.child("test-libs_{time}{100000.rand.Int}").IO;
    try mkdirs($precomp-path);
    LEAVE { sleep 1; try rm($precomp-path, :d, :f, :r) }

    my $distribution = Zef::Distribution.new(:$path, :$precomp-path);
    $distribution does Zef::Roles::Installing[$precomp-path];
    my @source-files = $distribution.provides(:absolute).values;

    my $results = $distribution.install(:$path);

    ok $results.list.elems,                        "Got non-zero number of results"; 
    is $results.list.grep({ $_<ok>.so }).elems, 1, "All modules installed OK";
    is $results.list.[0].hash.<name>,       'Zef', "name:Zef matches in pass results";
    ok $precomp-path.IO.child('MANIFEST').IO.e,    "MANIFEST exists";
}, 'Zef can install zef';


done();