module Zef::Config;
use JSON::Tiny;

our $HOME = ($*DISTRO.is-win
    ?? $*SPEC.join(%*ENV<HOMEDRIVE>, %*ENV<HOMEPATH>,'')
    !! $*SPEC.join('', %*ENV<HOME>,''));

# todo: properly handle volume argument for all .catpath method calls
our $ZEF_DIR is export = $*SPEC.join(
    |$*SPEC.split($HOME).hash.<volume directory>, 
    $*SPEC.catdir($*SPEC.split($HOME).hash.<basename>,'.zef')
);

our $ZEF_CONFIG_FILE is export = $*SPEC.catpath('', $ZEF_DIR, 'config');

try { mkdir($ZEF_DIR) } unless $ZEF_DIR.IO.d;    

# todo: validate config file
$ZEF_CONFIG_FILE.IO.spurt('{"plugins": [ ]}') 
    unless $ZEF_CONFIG_FILE.IO ~~ :f;

our $config is export = from-json($ZEF_CONFIG_FILE.IO.slurp);

sub save-config is export {
    $ZEF_CONFIG_FILE.IO.spurt(to-json($config));
}

multi MAIN('config') is export {
    say $ZEF_CONFIG_FILE;
}

multi MAIN('plugin', *@plugins) is export {
    $config<plugins> = uniq($config<plugins>, @plugins);
    save-config;
}

multi MAIN('unplug', *@plugins) is export {
    $config<plugins>.map({ :delete if $_ ~~ @plugins.any});
    save-config;
}
