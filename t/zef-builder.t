use v6;
use Zef::Builder;
use Zef::Utils::PathTools;
use Test;
plan 1;



# Basic tests on default builder method
subtest {
    my $CWD     := $*CWD;
    my $save-to := $*SPEC.catdir($CWD,"test-libs_{time}{100000.rand.Int}").IO;

    my $lib-base  := $*SPEC.catdir($CWD, "lib").IO;
    my $blib-base = $*SPEC.catdir($save-to,"blib").IO;
    LEAVE {       # Cleanup
        sleep 1;  # bug-fix for CompUnit related pipe file race
        try rm($save-to, :d, :f, :r);
    }

    my @source-files  = ls($lib-base, :f, :r, d => False);
    my @target-files := gather for @source-files.grep({ $_.IO.basename ~~ / \.pm6? $/ }) -> $file {
        my $mod-path := $*SPEC.catdir($blib-base, "{$file.IO.dirname.IO.relative}").IO;
        my $target   := $*SPEC.catpath('', $mod-path.IO.path, "{$file.IO.basename}.{$*VM.precomp-ext}").IO;
        take $target.IO.path;
    }

    my $builder = Zef::Builder.new;
    my @results = $builder.pre-compile($CWD, :$save-to);

    is @results.elems, 1, '1 repo';
    my @result-expects = @results.[0].<curlfs>.list.map({ $_.precomp-path });
    for @target-files -> $file {
        is any(@result-expects), $file.IO.absolute, "Found: {$file.IO.path}";
    }
}, 'Zef::Builder';



done();
