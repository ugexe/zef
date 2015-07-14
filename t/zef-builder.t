use v6;
use Zef::Builder;
use Zef::Utils::PathTools;
use Test;
plan 1;



# Basic tests on default builder method
subtest {
    my $CWD     := $*CWD;
    my $save-to := $CWD.child("test-libs_{time}{100000.rand.Int}").IO;

    my $lib-base  = $CWD.child('lib').IO;
    my $blib-base = $save-to.child('blib').IO;
    LEAVE {       # Cleanup
        sleep 1;  # bug-fix for CompUnit related pipe file race
        try rm($save-to, :d, :f, :r);
    }

    my @source-files  = ls($lib-base, :f, :r, d => False);
    my @target-files = gather for @source-files.grep({ $_.IO.basename ~~ / \.pm6? $/ }) -> $file {
        my $mod-path = $blib-base.child("{$file.IO.dirname.IO.relative}").IO;
        my $target   = $mod-path.IO.child("{$file.IO.basename}.{$*VM.precomp-ext}").IO;
        take $target.IO.path;
    }

    my $builder = Zef::Builder.new;
    my @results = $builder.precomp($CWD, :$save-to);

    is @results.elems, 1, '1 repo';

    my @expecting = @results.[0].<curlfs>.list.map({ $_.precomp-path });
    for @target-files -> $file {
        ok $file.IO.absolute ~~ any(@expecting), "Found: {$file.IO.path}";
    }
}, 'Zef::Builder';



done();
