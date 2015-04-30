use v6;
use Zef::Installer;
use Zef::Utils::FileSystem;
plan 1;
use Test;

my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
try mkdirs($save-to.IO.path);
LEAVE rm($save-to.IO.path, :d, :f, :r);

my $installer = Zef::Installer.new;
lives_ok { $installer.install(:$save-to, "META6.json") }, "installer lived";

done();