use v6;
use Zef::Authority;
use Test;

my $ssl = try { require IO::Socket::SSL } !~~ Nil ?? True !! False;

plan $ssl ?? 5 !! 2;

my $authority;

if $ssl {
  $authority = Zef::Authority.new;
  nok $authority.register(username => 'zef', password => 'pass'), "Username already registered";

  $authority = Zef::Authority.new;
  nok $authority.login(username => 'zef', password => 'pass'), "Login failed";

  $authority = Zef::Authority.new;
  ok $authority.login(username => 'zef', password => 'zef'), "Login worked";
}

$authority = Zef::Authority.new;
ok $authority.search('zef'), "Got modules (search: zef)";

$authority = Zef::Authority.new;
nok $authority.search("#"), "Got 0 modules (search: #)";

done();
