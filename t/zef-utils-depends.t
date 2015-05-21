use v6;
use Zef::Utils::PathTools;
use Zef::Utils::Depends;
plan 1;
use Test;


# Test parsing out POD from modules
subtest {
    my $tlib-dir   = $*SPEC.catdir($?FILE.IO.dirname, 'lib').IO;
    my $tlib-file  = $*SPEC.catpath('', $tlib-dir.IO.path, 'depends.pm6').IO;
    my @libs       = $tlib-dir.IO.ls(:r, :f, d => False);
    my @depends    = Zef::Utils::Depends.build-dep-tree: extract-deps(@libs);

    is @depends.[0].<depends>.elems, 2, 'We only got two dependencies';
    ok @depends.[0].<depends>.grep('This::One'), 'This::One depended - not in pod';
    ok @depends.[0].<depends>.grep('This::One::Too'), 'This::One::Too depended - not in pod';
    ok not @depends.[0].<depends>.grep('Peter'), 'Peter not depended - in pod';
    ok not @depends.[0].<depends>.grep('Peter::Allen'), 'Peter::Allen not depended - in pod';
    ok not @depends.[0].<depends>.grep('Dill::Pickle'), 'Dill::Pickle not depended - in pod';
}, 'Basic - Single level, ignore pod';

done;
