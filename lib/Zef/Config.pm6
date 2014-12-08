module Zef::Config;
use JSON::Tiny;
my $fs   = $*DISTRO.is-win ?? '\\' !! '/';
my $path = (%*ENV<zefconfig> // ($*DISTRO.is-win ?? 
              "{%*ENV<HOMEDRIVE>}$fs{%*ENV<HOMEPATH>}$fs"
           !! "{%*ENV<HOME>}$fs")
           ~  ".zef");

mkdir("$path") if "$path".IO !~~ :d;
"{$path ~ $fs}config".IO.spurt('{
  "plugins": [ ]
}') if "{$path ~ $fs}config".IO !~~ :f;

our $config is export = from-json(
  (%*ENV<zefconfig> // "{$path ~ $fs}config").IO.slurp
);

sub save-config is export {
  "{$path ~ $fs}config".IO.spurt(to-json($config));
}

multi MAIN('config') is export {
  "{$path ~ $fs}config".say;
}

multi MAIN('plugin', *@plugins) is export {
  for @plugins {
    say $_ ~~ $config<plugins>.any ?? "$_ true" !! "$_ false";
    $config<plugins>.push($_) unless $_ ~~ $config<plugins>.any;
  }
  save-config;
}

multi MAIN('unplug', *@plugins) is export {
  my @newplugins;
  for @($config<plugins>) {
    @newplugins.push($_) unless $_ ~~ @plugins.any;
  }
  $config<plugins> = @newplugins;
  save-config;
}
