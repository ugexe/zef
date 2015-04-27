use v6;
use Zef::Installer;
plan 1;
use Test;

my $save-to = $*SPEC.catdir($*TMPDIR, time);
try mkdir($save-to);
LEAVE Zef::Utils::FileSystem.new( path => $save-to.path ).rm(:d, :f, :r);

my $installer = Zef::Installer.new;
lives_ok { $installer.install(:$save-to, "META6.json") }, "installer lived";

done();