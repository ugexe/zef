unit module Zef::Config;

# ideally this would load a chain of config files from most to least broad in scope
# and merge them as appropriate (like NuGet). For now it just loads the first one it finds.
sub ZEF-CONFIG  is export {
    state %config = %(from-json( find-config().slurp ));
    once %config<Store>.subst-mutate(/'{$*HOME}' || '$*HOME'/, $*HOME // $*TMP, :g);
    %config;
}

sub find-config is export {
    first *.e, (
        "config.json".IO,
        ($*HOME // $*CWD).child('.zef').child('config.json'),
        %?RESOURCES<config.json>,
    )
}
