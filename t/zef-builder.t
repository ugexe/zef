use v6;
use Zef::Builder;
use Zef::Utils::PathTools;
use Test;
plan 1;



# Basic tests on default builder method
subtest {
    my $path    := $*CWD;
    my $save-to := $path.child("test-libs_{time}{100000.rand.Int}").IO;

    my $lib-base  = $path.child('lib').IO;
    my $blib-base = $save-to.IO;
    LEAVE {       # Cleanup
        sleep 1;  # bug-fix for CompUnit related pipe file race
        try rm($save-to, :d, :f, :r);
    }

    my @source-files = ls($lib-base, :f, :r, d => False);
    my @target-files = @source-files\
        .grep({ $_.IO.basename ~~ / \.pm6? $/ })\
        .map({ $blib-base.child("{$_.IO.relative($path)}.{$*VM.precomp-ext}").IO });

    my $builder = Zef::Builder.new(:$path, precomp-path => $blib-base);
    my $results = $builder.precomp(:force);

    ok $results;
    ok $results.<ok>.so;
    ok $results.<curlfs>.list.elems;

    my @expected-abs-paths = $results.<curlfs>.list.map({ $_.IO.is-absolute ?? $_.IO !! $path.child($_.IO).IO });
    for @target-files -> $file {
        ok $file.IO.absolute ~~ any(@expected-abs-paths), "Found: {$file.IO.path}";
    }
}, 'Zef::Builder';



done();
