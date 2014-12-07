module Zef::Config;
use JSON::Tiny;
my $fs   = $*DISTRO.is-win ?? '\\' !! '/';
my $path = (%*ENV<zefconfig> // ($*DISTRO.is-win ?? 
              "{%*ENV<HOMEDRIVE>}$fs{%*ENV<HOMEPATH>}$fs"
           !! "{%*ENV<HOME>}$fs")
           ~  ".zef");

"$path".say;
mkdir("$path") if "$path".IO !~~ :d;
"{$path ~ $fs}config".IO.spurt('{
  "plugins": [ ]
}') if "{$path ~ $fs}config".IO !~~ :f;

our %config is export = from-json(
  (%*ENV<zefconfig> // "{$path ~ $fs}config").IO.slurp
);
