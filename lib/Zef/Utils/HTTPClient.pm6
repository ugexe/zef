use Zef::Grammars::HTTP::RFC7230; # http header/body
use Zef::Grammars::HTTP::RFC3986; # uri
try require IO::Socket::SSL;

class Zef::Utils::HTTPClient {
    has $!sock;
    has @.responses;

    # todo: handle chunked encoding and binary

    submethod connect($url) {
        my $uri    = Zef::Grammars::HTTP::RFC3986.parse($url);

        my $scheme = $uri.<URI-reference>.<URI>.<scheme> // 'http';
        my $host   = $uri.<URI-reference>.<URI>.<heir-part>.<authority>.<host>;
        my $port   = $uri.<URI-reference>.<URI>.<heir-part>.<authority>.<port> 
                            // ($scheme.Str ~~ /^https/ ?? 443 !! 80);

        $!sock = ::('IO::Socket::SSL') ~~ Failure 
            ??      IO::Socket::INET.new( host => $host.Str, port => $port.Int )
            !! ($scheme.Str ~~ /^https/ 
                    ?? ::('IO::Socket::SSL').new( host => $host.Str, port => $port.Int )
                    !! IO::Socket::INET.new( host => $host.Str, port => $port.Int )    );

        return $!sock;
    }


    method get(Str $url) {
        self.connect($url);
        $!sock.send("GET $url HTTP/1.1\r\nHost: {$!sock.host}\r\nConnection:close\r\n\r\n");

        my $response = Zef::Grammars::HTTP::RFC7230.parse($!sock.recv);
        
        given $response.<HTTP-message>.<start-line>.<status-line>.<status-code> {
            when /^ 2\d+ $/ { 
                @.responses.push({
                    header => $response.<HTTP-message>.<header-field>,
                    body   => $response.<HTTP-message>.<message-body>,
                });
            }

            default {
                die "[NYI] http-code: '$_'";
            }
        }

        return @.responses[*-1];
    }

    method post(Str $url, Str $payload?) {
        self.connect($url);
        my $path-part = Zef::Grammars::HTTP::RFC3986.parse($url).<URI-reference>.<URI>.<heir-part>.<path-abempty>.Str;
        $!sock.send("POST {$path-part} HTTP/1.1\r\nHost: {$!sock.host}\r\nContent-Length: {$payload.chars}\r\n\r\n{$payload}");

        my $response = Zef::Grammars::HTTP::RFC7230.parse($!sock.recv);

        given $response.<HTTP-message>.<start-line>.<status-line>.<status-code> {
            when /^ 2\d+ $/ { 
                @.responses.push({
                    header => $response.<HTTP-message>.<header-field>,
                    body   => $response.<HTTP-message>.<message-body>,
                });
            }

            default {
                die "[NYI] http-code: '$_'";
            }
        }

        return @.responses[*-1];        
    }
}