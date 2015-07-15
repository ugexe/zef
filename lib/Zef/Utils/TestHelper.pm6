unit module Zef::Utils::TestHelpher;
use Test;

my $started;
BEGIN { $started = 0 }
END {
    exit(255) unless $started;
}