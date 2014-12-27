module Zef::Config;
use JSON::Tiny;

our $*ZEF_CONFIG_FILE = BEGIN {
    # todo: properly handle volume argument for all .catpath method calls
    my $*ZEF_DIR = $*SPEC.catpath('', %*ENV<zefconfig> // ($*DISTRO.is-win
                    ?? $*SPEC.catdir(%*ENV<HOMEDRIVE>, %*ENV<HOMEPATH>)
                    !! %*ENV<HOME>)
                ,".zef");

    mkdir($*ZEF_DIR) unless $*ZEF_DIR.IO.d;
    $*SPEC.catpath('', $*ZEF_DIR, 'config');
}

# todo: validate config file
$*ZEF_CONFIG_FILE.IO.spurt('{"plugins": [ ]}') 
    unless $*ZEF_CONFIG_FILE.IO ~~ :f;

our $config is export = from-json($*ZEF_CONFIG_FILE.IO.slurp);

sub save-config is export {
    $*ZEF_CONFIG_FILE.IO.spurt: to-json($config);
}

multi MAIN('config') is export {
    say $*ZEF_CONFIG_FILE;
}

multi MAIN('plugin', *@plugins) is export {
    $config<plugins> = uniq($config<plugins>, @plugins);
    save-config;
}

multi MAIN('unplug', *@plugins) is export {
    $config<plugins>.map({ :delete if $_ ~~ @plugins.any});
    save-config;
}
