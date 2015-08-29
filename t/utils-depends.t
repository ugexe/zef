use v6;
use Test;
plan 1;

use Zef::Utils::PathTools;
use Zef::Utils::Depends;


# Test parsing out POD from modules
subtest {
    my $tlib-dir   = $?FILE.IO.dirname.IO.child('lib').IO;
    my $tlib-file  = $tlib-dir.IO.child('depends.pm6').IO;
    my @libs       = $tlib-dir.IO.ls(:r, :f, d => False);
    my @depends    = Zef::Utils::Depends.new(projects => extract-deps(@libs).grep(*.so).list).topological-sort;

    is @depends[0].elems, 2,                 'We only got two dependencies';
    ok @depends[0].grep('This::One'),        'This::One depended - not in pod';
    ok @depends[0].grep('This::One::Too'),   'This::One::Too depended - not in pod';
    ok not @depends[0].grep('Peter'),        'Peter not depended - in pod';
    ok not @depends[0].grep('Peter::Allen'), 'Peter::Allen not depended - in pod';
    ok not @depends[0].grep('Dill::Pickle'), 'Dill::Pickle not depended - in pod';
    ok $tlib-file.ACCEPTS(~@depends[1]),     'End of dependency chain (self) found';
}, 'Basic - Single level, ignore pod';
