use v6;
use Zef::Utils::FileSystem;
use Zef::Utils::Depends;
plan 6;
use Test;


# Test parsing out POD from modules
{
    my $tlib-dir   = $*SPEC.catdir($?FILE.IO.dirname, 'lib');
    my $tlib-file  = $*SPEC.catpath('', $tlib-dir, 'depends.pm6').IO;
    my %depends    = $_.hash for Zef::Utils::Depends.build( Zef::Utils::FileSystem.extract-deps($tlib-dir) );
  
    is %depends<dependencies>.elems, 2, 'We only got two dependencies';
    ok %depends<dependencies>.grep('This::One'), 'This::One depended - not in pod';
    ok %depends<dependencies>.grep('This::One::Too'), 'This::One::Too depended - not in pod';
    ok not %depends<dependencies>.grep('Peter'), 'Peter not depended - in pod';
    ok not %depends<dependencies>.grep('Peter::Allen'), 'Peter::Allen not depended - in pod';
    ok not %depends<dependencies>.grep('Dill::Pickle'), 'Dill::Pickle not depended - in pod';
}

done;
