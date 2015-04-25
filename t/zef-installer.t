use v6;
use Zef::Installer;
plan 1;
use Test;


# Basic tests on the base class
my $installer = Zef::Installer.new;
my $save-to = $*SPEC.catdir($*CWD, 'tmp');
mkdir $save-to;
lives_ok { $installer.install(:$save-to, "META6.json") }, "installer lived";
shell("rm -rf $save-to").exitcode;

done();