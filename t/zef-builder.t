use v6;
use Zef::Builder;
use Zef::Utils::FileSystem;
plan 2;
use Test;





# Basic tests on Plugin::PreComp
subtest { {
    my $CWD := $*CWD;
    my $lib-base  = $*SPEC.catdir($CWD, "lib").IO;
    my $blib-base = $*SPEC.catdir($CWD,"blib").IO;
    my $blib-lib  = $*SPEC.catdir($blib-base, "lib").IO;
    LEAVE rm($blib-base.IO.path, :d, :f, :r);

    my $builder = Zef::Builder.new( :plugins(["Zef::Plugin::PreComp"]) );
    my @precompiled = $builder.pre-compile($blib-base.IO.dirname).map: *.IO.relative;
    my @source-files = ls($lib-base.IO.path, :f, :r);
    my @target-files = @source-files.grep({ $_.IO.basename ~~ / \.pm6? $/ }).map({ $*SPEC.catdir('blib', "{$_.IO.relative}.{$*VM.precomp-ext}").IO });

    is any(@precompiled), "blib/lib/Zef.pm6.{$*VM.precomp-ext}", 'Zef::Builder::Plugin::PreComp pre-compile works';
    for @target-files -> $file {
        is $file.IO.path, any(@precompiled), "Found: {$file.IO.path}";
    }

} }, 'Plugin::Precomp';


# Basic tests on default builder method
subtest { {
    my $CWD := $*CWD;
    my $blib-base = $*SPEC.catdir($CWD,"blib").IO;
    LEAVE rm($blib-base.IO.path, :d, :f, :r);

    my $builder = Zef::Builder.new;
    my @results = $builder.pre-compile($CWD);
    
    ok all(@results.map(-> %h { %h<precomp>:exists })), 'Zef::Builder default pre-compile works';
} }, 'Zef::Builder';

done();
