use Zef::Net::HTTP;
use Zef::Net::URI;
use Zef::Net::HTTP::Request;
use Zef::Net::HTTP::Response;
use Zef::Net::HTTP::Transport;


# A http client using the grammar based Net::HTTP::Request, Net::HTTP::Response, and Net::URI
class Zef::Net::HTTP::Client {
    has $.auto-check is rw;
    has @.history;

    has HTTP::RoundTrip $.transporter;
    has HTTP::Response  $.responder;
    has HTTP::Request   $.requestor;

    submethod BUILD(
        HTTP::RoundTrip :$!transporter, 
        HTTP::Request   :$!requestor,
        HTTP::Response  :$!responder,
        Bool :$!auto-check,
    ) {
        $!responder   := Zef::Net::HTTP::Response                    unless $!responder;
        $!requestor   := Zef::Net::HTTP::Request                     unless $!requestor;
        $!transporter  = Zef::Net::HTTP::Transport.new(:$!responder) unless $!transporter;
    }

    method method($method, $url, :$body) {
        my $request  = $!requestor.new(:$method, :$url, :$body );
        my $response = $!transporter.round-trip($request);

        @.history.push: $response;

        if $.auto-check {
            fail "Response not understood" unless $response && $response.status-code;

            given $response.status-code {
                when /^2\d+$/ { }
                when /^301/     {
                    $response = self.send($method, ~$response.header.<Location>, :$body);
                }
                default {
                    die "[NYI] http-code: '$_'";
                }
            }
        }

        return $response;
    }

    method get(Str $url) {
        return $.method('GET', $url);
    }

    method post(Str $url, :$body) {
        return $.method('POST', $url, :$body);
    }
}