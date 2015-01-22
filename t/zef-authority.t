use v6;
use Zef::Authority;
plan 4;
use Test;

my $authority = Zef::Authority.new;
nok $authority.register(username => 'zef', password => 'pass'), "Username already registered";

$authority = Zef::Authority.new;
ok $authority.login(username => 'zef', password => 'zef'), "Login worked";

$authority = Zef::Authority.new;
ok $authority.search('zef'), "Got modules (search: zef)";

$authority = Zef::Authority.new;
nok $authority.search("#"), "Got 0 modules (search: #)";

done();