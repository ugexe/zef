use v6;
use Zef::Utils;
use Zef::Depends;
plan 6;
use Test;


# Test parsing out POD from modules
{
  my @depends = Zef::Depends.build(Zef::Utils.comb($*SPEC.catpath('', $?FILE.IO.dirname, 'lib')));
  my %depends = %(@depends.grep({ $_<file> ~~ / "{$*SPEC.catpath('', 'lib', 'depends.pm6')}" $$ / }));
  ok %depends<dependencies>.elems == 2, 'We only got two dependencies';
  ok %depends<dependencies>.grep('This::One'), 'This::One depended - not in pod';
  ok %depends<dependencies>.grep('This::One::Too'), 'This::One::Too depended - not in pod';
  ok not %depends<dependencies>.grep('Peter'), 'Peter not depended - in pod';
  ok not %depends<dependencies>.grep('Peter::Allen'), 'Peter::Allen not depended - in pod';
  ok not %depends<dependencies>.grep('Dill::Pickle'), 'Dill::Pickle not depended - in pod';
}

done;
