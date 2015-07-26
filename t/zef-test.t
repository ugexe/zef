use v6;
use Zef::Distribution;
use Zef::Roles::Testing;
use Zef::Roles::Processing;
use Test;
plan 1;


# Test default tester
subtest {
    my $path := $?FILE.IO.dirname.IO.parent;

    my $distribution = Zef::Distribution.new(:$path);
    $distribution does Zef::Roles::Testing;
    $distribution does Zef::Roles::Processing;
    my @cmds = $distribution.test-cmds;

    ok @cmds.elems > 1, "Created test commands";
}, 'Default tester';



done();