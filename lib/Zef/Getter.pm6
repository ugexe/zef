module Zef::Getter;
use Zef::Getter::HTTP;
use Zef::Getter::Git;

has @.getters   = <HTTP Git>;

# default getter install from file?