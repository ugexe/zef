use v6;
use Zef::Authority;
plan 1;
use Test;

my $authority = Zef::Authority.new;

ok $authority.search("zef"), 'Got modules';

done();