use Zef::Net::HTTP::Request;
use Zef::Net::HTTP::Response;
use Zef::Net::URI;

role Zef::Net::HTTP::Transport {
    try require IO::Socket::SSL;
    has $.can-ssl = !::("IO::Socket::SSL").isa(Failure);

    method connect(Zef::Net::HTTP::Request:D:) {
        my $uri  := self.uri;
        my $puri := self.proxy.uri if self.proxy.?uri;

        my $scheme = (?$puri && ?$puri.scheme ?? $puri.scheme !! $uri.scheme) // 'http';
        my $host   =  ?$puri && ?$puri.host   ?? $puri.host   !! $uri.host;
        my $port   = (?$puri && ?$puri.port   ?? $puri.port   !! $uri.port) // ($scheme eq 'https' ?? 443 !! 80);

        if $scheme eq 'https' && !$.can-ssl {
            die "Please install IO::Socket::SSL for SSL support";
        }

        return !$.can-ssl
            ??  IO::Socket::INET.new( :$host, :$port )
            !! $scheme ~~ /^https/ 
                    ?? ::('IO::Socket::SSL').new( :$host, :$port )
                    !! IO::Socket::INET.new( :$host, :$port );
    }

    method send(Zef::Net::HTTP::Request:D:) {
        my $socket = self.connect;
        $socket.send(self.Str);
        my $stream = Supply.from-list: gather while my $r = $socket.recv { take $r }
        return $stream.Channel;
    }
}

# A http client using the grammar based Net::HTTP::Request, Net::HTTP::Response, and Net::URI
class Zef::Net::HTTP::Client {
    has $.auto-check is rw;
    has @.history;

    my class RoundTrip {
        has $.request;
        has $.response;
    }


    method send(Str $method, Str $url, :$body) {
        my $request  = Zef::Net::HTTP::Request.new( :$method, :$url, :$body ) does Zef::Net::HTTP::Transport;
        my $response-stream = $request.send;
        my $response = Zef::Net::HTTP::Response.new( :message($response-stream.list) );


        @.history.push: RoundTrip.new(:$request, :$response);

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
        my $response = self.send('GET', $url);
        return $response;
    }

    method post(Str $url, :$body) {
        my $response = self.send('POST', $url, :$body);
        return $response;
    }
}