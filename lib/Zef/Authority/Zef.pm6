use Zef::Authority::Net;
use Zef::Net::HTTP::Client;
use Zef::Utils::Depends;


class Zef::Authority::Zef does Zef::Authority::Net {
    has $!ua      = Zef::Net::HTTP::Client.new;
    has @!mirrors = <http://zef.pm/api/projects>;

    method report { say "NYI" }
    method get    { say "NYI" }
    method update-projects {
        my $response = $!ua.get: @!mirrors.[0];
        @!projects = @(from-json($response.content));
    }
}