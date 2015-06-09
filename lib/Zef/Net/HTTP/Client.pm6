use Zef::Net::HTTP::RoundTrip;
use Zef::Net::HTTP::Request;
use Zef::Net::HTTP::Response;
use Zef::Net::URI;


# A http client using the grammar based Net::HTTP::Request, Net::HTTP::Response, and Net::URI
class Zef::Net::HTTP::Client {
    has $.auto-check is rw;
    has @.history;

    method method($method, $url, :$body) {
        my $request  = Zef::Net::HTTP::Request.new(:$method, :$url, :$body );
        my $rt = Zef::Net::HTTP::RoundTrip.new(:$request);
        $rt.init;

        @.history.push: $rt;

        if $.auto-check {
            fail "Response not understood" unless $rt.response && $rt.response.status-code;

            given $rt.response.status-code {
                when /^2\d+$/ { }
                when /^301/     {
                    $rt.response = self.send($method, ~$rt.response.header.<Location>, :$body);
                }
                default {
                    die "[NYI] http-code: '$_'";
                }
            }
        }

        return $rt.response;
    }

    method get(Str $url) {
        return $.method('GET', $url);
    }

    method post(Str $url, :$body) {
        return $.method('POST', $url, :$body);
    }
}