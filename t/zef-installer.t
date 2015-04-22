use v6;
use Zef::Installer;
plan 2;
use Test;


# Basic tests on the base class
my $installer = Zef::Installer.new;
my $save_to = $*SPEC.catdir($*CWD, 'tmp');
lives_ok { $installer.install(:$save_to, "META6.json") }, "installer lived";
is shell("rm -rf $save_to").exitcode, 0, 'deleted test install folder';

done();