unit module Zef::Utils::Helper;
use Test;

my $started;
BEGIN { $started = 0 }
END {
    exit(255) unless $started;
}