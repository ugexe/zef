use v6;
use Zef::Depends;
plan 7;
use Test;

# Test can .comb without an instance
{
    ok Zef::Depends.can('comb'), 'Zef::Depends can do comb method';
}

# Test parsing out POD from modules
{
  my @depends = Zef::Depends.comb($*SPEC.catpath('', $?FILE.IO.dirname, 'lib'));
  my %depends = %(@depends.grep({ $_<file> eq $*SPEC.catpath('', 'lib', 'depends.pm6') }));
  ok %depends<dependencies>.elems == 2, 'We only got two dependencies';
  ok %depends<dependencies>.grep('This::One'), 'This::One depended - not in pod';
  ok %depends<dependencies>.grep('This::One::Too'), 'This::One::Too depended - not in pod';
  ok not %depends<dependencies>.grep('Peter'), 'Peter not depended - in pod';
  ok not %depends<dependencies>.grep('Peter::Allen'), 'Peter::Allen not depended - in pod';
  ok not %depends<dependencies>.grep('Dill::Pickle'), 'Dill::Pickle not depended - in pod';
}

done;
