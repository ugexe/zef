use Zef::Net::HTTP;
use Zef::Net::URI;
use Zef::Net::HTTP::Request;
use Zef::Net::HTTP::Response;
use Zef::Net::HTTP::Transport;


# A http client using the grammar based Net::HTTP::Request, Net::HTTP::Response, and Net::URI
class Zef::Net::HTTP::Client {
    has $.auto-check is rw;
    has @.history;
    has %.headers    is rw;
    has HTTP::RoundTrip $.transporter;
    has HTTP::Response  $.responder;
    has HTTP::Request   $.requestor;

    submethod BUILD(
        HTTP::RoundTrip :$!transporter,
        HTTP::Request   :$!requestor,
        HTTP::Response  :$!responder,
        Bool :$!auto-check,
        :%!headers,
    ) {
        $!responder   := Zef::Net::HTTP::Response                    unless $!responder;
        $!requestor   := Zef::Net::HTTP::Request                     unless $!requestor;
        $!transporter := Zef::Net::HTTP::Transport.new(:$!responder) unless $!transporter;
    }

    method method($method, $url, :$body) {
        my $request  = $!requestor.new(:$method, :$url, :$body, :%!headers);
        my $response = $!transporter.round-trip($request);
        @!history.append: $response;

        if ?$!auto-check {
            die "Response not understood" unless $response && $response.status-code;

            given $response.status-code {
                when /^2\d\d$/ { }
                when /^3\d\d$/ {
                    my $location = Zef::Net::URI.new( :url(~$response.headers.<Location>) );
                    my $forward-to = $location.absolute("{$request.uri.scheme}://{$request.uri.host}");

                    # We put the original response in the history already. We set $response now 
                    # so after all forwarding is done we can return the final response.
                    $response = self.method( $request.method, $forward-to.url, :$body );
                    # &?ROUTINE with args is broken
                    # $reponse = &?ROUTINE( $request.method, $forward-to.url, :body($request.body) );
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
        return my $response = $.method('POST', $url, :$body);
    }
}