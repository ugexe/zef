use v6;
use Zef::Installer;
use Zef::Utils::PathTools;
plan 1;
use Test;

my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
try mkdirs($save-to);
LEAVE rm($save-to, :d, :f, :r);

my $installer = Zef::Installer.new;
lives_ok { $installer.install(:$save-to, "META6.json") }, "installer lived";

done();