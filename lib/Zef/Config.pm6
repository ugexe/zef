unit module Zef::Config;

# ideally this would load a chain of config files from most to least broad in scope
# and merge them as appropriate (like NuGet). For now it just loads the first one it finds.
sub ZEF-CONFIG is export {
    state %config = %(from-json( find-config().slurp ));
    once {
        %config{$_.key} = $_.value.subst(/'{$*HOME}' || '$*HOME'/, $*HOME // $*TMP, :g)\
            for %config.grep(*.key.ends-with('Dir'));
    }
    %config;
}

sub find-config is export {
    first *.e, (
        "config.json".IO,
        ($*HOME // $*CWD).child('.zef').child('config.json'),
        %?RESOURCES<config.json>,
    )
}

sub config-plugin-lookup($config is copy) is export {
    my $lookup;
    my sub do-lookup($node) {
        if $node ~~ Hash {
            for @$node -> $sub-node {
                if $sub-node.value ~~ Str | Int && $sub-node.key eq any(<short-name module>) {
                    $lookup{$sub-node.value} := $node;
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