use v6;
use Zef::Distribution::Local;
use Zef::Roles::Precompiling;
use Zef::Roles::Processing;
use Zef::Utils::PathTools;
use Test;
plan 1;



# Basic tests on default builder method
subtest {
    my $path    := $?FILE.IO.dirname.IO.parent; # ehhh
    my $save-to := $path.child("test-libs_{time}{100000.rand.Int}").IO;
    my $precomp-path = $save-to.IO.child('lib');

    LEAVE {       # Cleanup
        sleep 1;  # bug-fix for CompUnit related pipe file race
        try rm($save-to, :d, :f, :r);
    }

    my $distribution = Zef::Distribution::Local.new(:$path, :$precomp-path);
    $distribution does Zef::Roles::Precompiling;
    $distribution does Zef::Roles::Processing;

    my @source-files = $distribution.provides(:absolute).values.unique;
    my @target-files = $distribution.provides-precomp(:absolute).values.unique;

    my @cmds = $distribution.precomp-cmds.list;
    ok @cmds.elems > 1, "Created precomp commands";    

    $distribution.queue-processes($_) for @cmds;

    await $distribution.start-processes;

    is $distribution.passes.elems, @source-files.elems, "Found expected precompiled files";
    is $distribution.failures.elems, 0, "No apparent precompilation failures";

    for @target-files -> $file {
        ok $file.IO.e, "Found: {$file.IO.relative($path)}";
    }
}, 'Zef::Builder';
