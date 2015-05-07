use v6;
use Zef::Authority;
plan 2;
use Test;

subtest {
    my $authority  = Zef::Authority.new;
    my @results    = $authority.search('zef');
    my @no-results = $authority.search("#");

    ok @results.elems, "Got modules (search: zef)";
    is @no-results.elems, 0, "Got 0 modules (search: #)";
}, 'SSL not required';

subtest {
    ENTER {
        try require IO::Socket::SSL;
        if ::('IO::Socket::SSL') ~~ Failure {
            print("ok 2 - # Skip: IO::Socket::SSL not available\n");
            return;
        }
    }

    my $authority = Zef::Authority.new;
    my %response  = $authority.register(username => 'zef', password => 'pass');

    is %response.<failure>, 1, "Username already registered";
    nok $authority.login(username => 'zef', password => 'pass'), "Login failed";
    ok $authority.login(username => 'zef', password => 'zef'), "Login worked";
}, 'SSL required';

done();