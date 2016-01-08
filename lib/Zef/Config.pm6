unit module Zef::Config;

# ideally this would load a chain of config files from most to least broad in scope
# and merge them as appropriate (like NuGet). For now it just loads the first one it finds.
sub ZEF-CONFIG  is export {
    state %config = %(from-json(find-config().IO.slurp));
    once %config<store>.subst-mutate(/'{$*HOME}' || '$*HOME'/,   $*HOME, :g);
    %config;
}

sub find-config {
    ("config.json", %?RESOURCES<config.json>, "resources/config.json").first(*.IO.e);
}
