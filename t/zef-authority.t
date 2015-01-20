use v6;
use Zef::Authority;
plan 2;
use Test;

my $authority = Zef::Authority.new;

ok $authority.search('zef'), "Got modules (search: zef)";
nok $authority.search("''"), "Got 0 modules (search: '')";

done();