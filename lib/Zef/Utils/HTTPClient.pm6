use Zef::Grammars::HTTP;

try require IO::Socket::SSL;

# todo: * handle chunked encoding and binary
#       * test if proxy actually works
class Zef::Utils::HTTPClient {
    has $!sock;
    has $.can-ssl = !::("IO::Socket::SSL").isa(Failure);
    has $.auto-check is rw;
    has @.history;
    has $.proxy-url is rw;
    has $.user is rw;
    has $.pass is rw;

    my class RoundTrip {
        has $.request;
        has $.response;
    }

    submethod connect(Zef::Grammars::URI $uri) {
        my $proxy-uri = Zef::Grammars::URI.new(url => $!proxy-url) if $!proxy-url;
        my $scheme = (?$proxy-uri && ?$proxy-uri.scheme ?? $proxy-uri.scheme !! $uri.scheme) // 'http';
        my $host   = ?$proxy-uri && ?$proxy-uri.host    ?? $proxy-uri.host   !! $uri.host;
        my $port   = (?$proxy-uri && ?$proxy-uri.port   ?? $proxy-uri.port   !! $uri.port) // ($scheme eq 'https' ?? 443 !! 80);

        if $scheme eq 'https' && !$!can-ssl {
            die "Please install IO::Socket::SSL for SSL support";
        }

        $!sock = !$!can-ssl
            ??  IO::Socket::INET.new( host => $host, port => $port )
            !! $scheme ~~ /^https/ 
                    ?? ::('IO::Socket::SSL').new( host => $host, port => $port )
                    !! IO::Socket::INET.new( host => $host, port => $port );
    }

    method send($action, $url, :$payload) {
        my $request    = Zef::Grammars::HTTPRequest.new( :$action, :$url, :$payload, :$.user, :$.pass );
        my $connection = self.connect($request.uri);
        $connection.send(~$request);
        my $response   = Zef::Grammars::HTTPResponse.new(message => $connection.recv);
        @.history.push: RoundTrip.new(:$request, :$response);

        if $.auto-check {
            given $response.status-code {
                when /^2\d+$/ { }
                when /^301/     {
                    $response = self.request($action, ~$response.header.<Location>, :$payload);
                }
                default {
                    die "[NYI] http-code: '$_'";
                }
            }
        }

        return $response;
    }

    method get(Str $url) {
        my $response = self.send('GET', $url);
        return $response;
    }

    method post(Str $url, :$payload) {
        my $response = self.send('POST', $url, :$payload);
        return $response;
    }
}