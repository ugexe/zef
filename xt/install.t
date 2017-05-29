use v6;
use Test;
plan 3;

use Zef;
use Zef::Client;
use Zef::Utils::FileSystem;
use Zef::Identity;
use Zef::Config;


my $path = $*TMPDIR.child("zef").child("{time}.{$*PID}");
my $bin-dir     = $path.child('bin');
my $dist-dir    = $path.child('dist');
my $sources-dir = $path.child('sources');
my CompUnit::Repository @cur = CompUnit::RepositoryRegistry\
    .repository-for-spec("inst#{$path.absolute}", :next-repo($*REPO));
END { try delete-paths($path, :r, :d, :f, :dot) }

my $guess-path = $?FILE.IO.parent.parent.child('resources/config.json');
my $config-file = $guess-path.e ?? ~$guess-path !! Zef::Config::guess-path();
my $config      = Zef::Config::parse-file($config-file);
$config<RootDir>  = "$path/.cache";
$config<StoreDir> = "$path/.cache/store";
$config<TempDir>  = "$path/.cache/tmp";

my @installed; # keep track of what gets installed for the optional uninstall test at the end


my $client = Zef::Client.new(:$config);
# Keeps every $client.install from printing to stdout
sub test-install($path = $?FILE.IO.parent.parent) {
    # Need to remove all stdout/stderr output from Zef::Client, or at least complete
    # the message passing mechanism so it can be turned off at will. Until then just
    # turn off stdout for this test as it will output details to stdout even when !$verbose)
    temp $*OUT = class :: { method print(|) {}; method flush(|) {}; };
    # No test distribution to install yet, so test install zef itself
    my $candidate = Candidate.new(
        dist => Zef::Distribution::Local.new($path),
        uri  => $path.IO.absolute,
        as   => ~$path,
        from => ~$?FILE,
    );
    my @got = |$client.install( :to(@cur), :!test, :!fetch, $candidate );
    @installed = unique(|@installed, |@got, :as(*.dist.identity));
}


#########################################################################################


subtest {
    my @installed = test-install();

    is +@installed, 1, 'Installed a single module';
    is +$dist-dir.dir.grep(*.f), 1, 'A single distribution file should exist';

    # $dist-info is the content of a file that holds meta information, such as
    # the new names of the files. If ~$filename from $sources-dir is found in
    # ~$dist-info then just assume everything worked correctly
    my $filename  = $sources-dir.dir.first(*.f).basename;
    my $dist-info = $dist-dir.dir.first(*.f).slurp;
    ok $dist-info.contains($filename), 'Verify install succeeded';
}, 'install';


subtest {
    subtest {
        test-install(); # XXX: Need to find a way to test when this fails
        is +@installed, 1, 'Installed nothing new';
        is +$dist-dir.dir.grep(*.f), 1, 'Only a single distribution file should still exist';
        my $filename  = $sources-dir.dir.first(*.f).basename;
        my $dist-info = $dist-dir.dir.first(*.f).slurp;
        ok $dist-info.contains($filename), 'Verify previous install appears valid';
    }, 'Without force';

    subtest {
        temp $client.force-install = True;
        my @installed = test-install();

        is +@installed, 1, 'Install count remains 1';
        is +$dist-dir.dir.grep(*.f), 1, 'Only a single distribution file should still exist';
        my $filename  = ~$sources-dir.dir.first(*.f).basename;
        my $dist-info = ~$dist-dir.dir.first(*.f).slurp;
        ok $dist-info.contains($filename), 'Verify reinstall appears valid';
    }, 'With force-install';
}, 'reinstall';


subtest {
    +@cur.grep(*.can('uninstall')) == 0
        ?? skip("Need a newer rakudo for uninstall")
        !! do {
            my @uninstalled = Zef::Client.new(:$config).uninstall( :from(@cur), |@installed>>.dist>>.identity );
            is +@uninstalled,     1, 'Uninstalled a single module';
            is +$sources-dir.dir, 0, 'No source files should remain';
            is +$dist-dir.dir,    0, 'No distribution files should remain';
        }
}, 'uninstall';
