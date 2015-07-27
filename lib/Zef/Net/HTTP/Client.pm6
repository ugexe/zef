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
        $!transporter := Zef::Net::HTTP::Transport.new(:$!responder) unless $!transporter;
    }

    method method($method, $url, :$body) {
        my $request  := $!requestor.new(:$method, :$url, :$body);
        my $response := $!transporter.round-trip($request);

        @!history.push: $response;

        if $!auto-check {
            fail "Response not understood" unless $response && $response.status-code;

            given $response.status-code {
                when /^2\d\d$/ { }
                when /^3\d\d$/ {
                    my $location   := Zef::Net::URI.new(url => ~$response.headers.<Location>);
                    my $forward-to := $location.is-relative 
                        ?? $location.rel2abs("{$request.uri.scheme}://{$request.uri.host}")
                        !! $location;

                    # We put the original response in the history already. We set $response now 
                    # so after all forwarding is done we can return the final response.
                    &?ROUTINE( $request.method, $forward-to.url, :body($request.body) );
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