use Zef;
unit module Zef::Config;

our sub parse-file($path) {
    my %config = %(from-json( $path.IO.slurp ));

    %config{$_.key} = $_.value.subst(/'{$*HOME}' || '$*HOME'/, $*HOME // $*TMP, :g)\
        for %config.grep(*.key.ends-with('Dir'));

    %config<DefaultCUR> //= 'auto';

    %config;
}

our sub guess-path {
    my $local-conf   = $*HOME.child('.zef').child('config.json');
    my $default-conf = %?RESOURCES<config.json>;

    return $local-conf if $local-conf.e;
    return $default-conf;
}

our sub plugin-lookup($config) {
    my $lookup;
    my sub do-lookup($node) {
        if $node ~~ Hash {
            for @$node -> $sub-node {
                if $sub-node.value ~~ Str | Int && $sub-node.key eq any(<short-name module>) {
                    $lookup{$sub-node.value}.push($node);
                    next;
                }
                do-lookup($sub-node.value);
            }
        }
        elsif $node ~~ Array {
            do-lookup($_) for $node.cache;
        }
    }
    do-lookup($config);
    $lookup;
}
