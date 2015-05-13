use v6;
use Zef::Builder;
use Zef::Utils::PathTools;
plan 1;
use Test;



# Basic tests on default builder method
subtest {
    my $CWD := $*CWD;
    my $lib-base  := $*SPEC.catdir($CWD, "lib").IO;
    my $blib-base = $*SPEC.catdir($CWD,"blib").IO;
    LEAVE try rm($blib-base, :d, :f, :r);

    my @source-files  = ls($lib-base, :f, :r, d => False);
    my @target-files := gather for @source-files.grep({ $_.IO.basename ~~ / \.pm6? $/ }) -> $file {
        my $mod-path := $*SPEC.catdir('blib', "{$file.IO.dirname.IO.relative}").IO;
        my $target   := $*SPEC.catpath('', $mod-path.IO.path, "{$file.IO.basename}.{$*VM.precomp-ext}").IO;
        take $target.IO.path;
    }

    my $builder = Zef::Builder.new;
    my @results = $builder.pre-compile($CWD);

    is @results.grep({ $_.has-precomp }).elems, @results.elems, "Default builder precompiled all modules: {@results.elems}";
    is @results.grep({ $_.precomp-path.IO.f }).elems, @results.elems, "precomp-path points to real file";
    for @target-files -> $file {
        is any(@results.map({ $_.precomp-path })), $file.IO.absolute, "Found: {$file.IO.path}";
    }
}, 'Zef::Builder';



done();
