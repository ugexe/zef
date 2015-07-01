use v6;
use Zef::Authority::Zef;
use Test;
plan 2;


subtest {
    ok my $authority = Zef::Authority::Zef.new;
    #my @results    = $authority.search('zef');
    #my @no-results = $authority.search("#");

    #ok @results.elems, "Got modules (search: zef)";
    #is @no-results.elems, 0, "Got 0 modules (search: #)";
}, 'SSL not required';

subtest {
    unless Zef::Net::HTTP::Client.new.transporter.dialer.?can-ssl {
        print("ok 2 - # Skip: Can't do SSL. Is IO::Socket::SSL available?\n");
        return;
    }

    ok my $authority = Zef::Authority::Zef.new;
    #my %response  = $authority.register(username => 'zef', password => 'pass');

    #is %response.<failure>, 1, "Username already registered";
    #nok $authority.login(username => 'zef', password => 'pass'), "Login failed";
    #ok $authority.login(username => 'zef', password => 'zef'), "Login worked";
}, 'SSL required';

done();
