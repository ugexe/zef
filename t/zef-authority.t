use v6;
use Zef::Authority;
plan 2;
use Test;

my $authority;

subtest {
    $authority = Zef::Authority.new;
    ok $authority.search('zef'), "Got modules (search: zef)";

    $authority = Zef::Authority.new;
    nok $authority.search("#"), "Got 0 modules (search: #)";
}, 'SSL not required';

subtest {
    if ::('IO::Socket::SSL') ~~ Failure {
        print("    1..3\n");
        print("ok 2 - # Skip: IO::Socket::SSL not available\n");
        return;
    }
    
    $authority = Zef::Authority.new;
    nok $authority.register(username => 'zef', password => 'pass'), "Username already registered";

    $authority = Zef::Authority.new;
    nok $authority.login(username => 'zef', password => 'pass'), "Login failed";

    $authority = Zef::Authority.new;
    ok $authority.login(username => 'zef', password => 'zef'), "Login worked";
}, 'SSL required';

done();
