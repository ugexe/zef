use v6;
use Zef::Authority;
plan 3;
use Test;

my $authority = Zef::Authority.new;

nok $authority.register(username => 'zef', password => 'pass'); # username already registered
#ok $authority.login(username => 'zef', password => 'zef');

ok $authority.search('zef'), "Got modules (search: zef)";
nok $authority.search("''"), "Got 0 modules (search: '')";

done();