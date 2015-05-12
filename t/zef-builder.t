use v6;
use Zef::Builder;
use Zef::Utils::PathTools;
plan 2;
use Test;


# Basic tests on Plugin::PreComp
# Do this before 'default' test otherwise some heisenbug occurs
# Likely due to testing by using CompUnit.precomp on self
subtest {
    try require Zef::Plugin::PreComp;
    if ::('Zef::Plugin::PreComp') ~~ Failure {
        print("ok - # Skip: Zef::Plugin::PreComp not available\n");
        return;
    }

    my $CWD := $*CWD;
    my $lib-base  := $*SPEC.catdir($CWD, "lib").IO;
    my $blib-base := $*SPEC.catdir($CWD,"blib").IO;
    my $blib-lib  := $*SPEC.catdir($blib-base, "lib").IO;
    LEAVE try rm($blib-base, :d, :f, :r);

    my $builder = Zef::Builder.new( :plugins(["Zef::Plugin::PreComp"]) );
    
    my @precompiled   = $builder.pre-compile($lib-base).map: *.IO.relative;
    my @source-files  = ls($lib-base, :f, :r, d => False);
    my @target-files := gather for @source-files.grep({ $_.IO.basename ~~ / \.pm6? $/ }) -> $file {
        my $mod-path := $*SPEC.catdir('blib', "{$file.IO.dirname.IO.relative}").IO;
        my $target   := $*SPEC.catpath('', $mod-path.IO.path, "{$file.IO.basename}.{$*VM.precomp-ext}").IO;
        take $target.IO.path;
    }

    my $comp-path = $*SPEC.catpath('', $blib-lib, "Zef.pm6.{$*VM.precomp-ext}").IO;
    is any(@precompiled), $comp-path.relative, 'Sanity';
    
    for @target-files -> $file {
        is any(@precompiled), $file.IO.path, "Found: {$file.IO.path}";
    }

}, 'Plugin::PreComp';


# Basic tests on default builder method
subtest {
    my $CWD := $*CWD;
    my $blib-base = $*SPEC.catdir($CWD,"blib").IO;
    LEAVE try rm($blib-base, :d, :f, :r);

    my $builder = Zef::Builder.new;
    my @results = $builder.pre-compile($CWD);

    is @results.grep({ $_.has-precomp }).elems, @results.elems, "Default builder precompiled all modules: {@results.elems}";
}, 'Zef::Builder';



done();
