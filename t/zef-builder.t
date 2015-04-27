use v6;
use Zef::Builder;
use Zef::Utils::FileSystem;
plan 2;
use Test;


# Basic tests on default builder method
subtest { {
    my $path = "{$*CWD}/blib".IO;
    LEAVE Zef::Utils::FileSystem.new(path => $path // return).rm(:d, :f, :r);

    my $builder = Zef::Builder.new;
    my @results = $builder.pre-compile($*CWD);
    
    ok all(@results.map(-> %h { %h<precomp>:exists })), 'Zef::Builder default pre-compile works';
} }, 'Zef::Builder';


# Basic tests on Plugin::PreComp
subtest { {
    my $path = "{$*CWD}/blib".IO;
    LEAVE Zef::Utils::FileSystem.new(path => $path // return).rm(:d, :f, :r);

    lives_ok { use Zef::Plugin::PreComp; }, 'Zef::Plugin::PreComp `use`-able to test with';
    my $builder = Zef::Builder.new( :plugins(["Zef::Plugin::PreComp"]) );
    my @precompiled = $builder.pre-compile($*CWD);
    # TODO: actually check for all files being precompiled
    is any(@precompiled), "$*CWD/blib/lib/Zef.pm6.{$*VM.precomp-ext}", 'Zef::Builder default pre-compile works';

} }, 'Plugin::Precomp';


done();
