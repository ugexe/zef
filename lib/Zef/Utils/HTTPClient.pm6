use Zef::Grammars::HTTP;
use Zef::Utils::Base64;

try require IO::Socket::SSL;

# todo: * handle chunked encoding and binary
#       * test if proxy actually works
#       * use in Zef::Getter default    
class Zef::Utils::HTTPClient {
    has $!sock;
    has $.auto-check;
    has @.responses;
    has $!proxy;
    has $!proxy-auth;
    has $!auth;

    submethod BUILD(:$!proxy, :$!auto-check, :$!auth) {
        if $!proxy {
            $!proxy      = Zef::Grammars::URI.new(url => $!proxy);
            $!proxy-auth = Zef::Utils::Base64.new.b64encode($!proxy.user-info) if $!proxy.user-info;
        }
        
        $!auth = Zef::Utils::Base64.new.b64encode($!auth) if $!auth;
    }

    submethod connect($url) {
        my $uri    = Zef::Grammars::URI.new(url => $url);
        my $scheme = lc($!proxy  ?? $!proxy.scheme !! ($uri.scheme // 'http'));
        my $host   =    $!proxy  ?? $!proxy.host   !! $uri.host;
        my $port   =   ($!proxy ?? $!proxy.port   !! $uri.port) // ($scheme.Str ~~ /^https/ ?? 443 !! 80);
        my $auth   = $uri.user-info ?? Zef::Utils::Base64.new.b64encode($uri.user-info) !! ($!auth // Empty);

        if $scheme eq 'https' && ::('IO::Socket::SSL') ~~ Failure {
            die "Please install IO::Socket::SSL for SSL support";
        }

        $!sock = ::('IO::Socket::SSL') ~~ Failure 
            ??      IO::Socket::INET.new( host => $host, port => $port )
            !! ($scheme.Str ~~ /^https/ 
                    ?? ::('IO::Socket::SSL').new( host => $host, port => $port )
                    !! IO::Socket::INET.new( host => $host, port => $port )    );
    }

    method request($action, $url, $payload?) {
        my $conn = self.connect($url);


        my $req =        "$action $url HTTP/1.1"                          # request
            ~   "\r\n" ~ "Host: {$conn.host}"                             # mandatory headers
            ~ (("\r\n" ~ "Content-Length: {$payload.chars}") if $payload) # optional header fields
            ~ (("\r\n" ~ "Proxy-Authorization: Basic {$!proxy-auth}") if $!proxy-auth)
            ~ (("\r\n" ~ "Authorization: Basic {$!auth}") if $!auth)
            ~   "\r\n" ~ "Connection: close\r\n\r\n"                      # last header field
            ~ ($payload if $payload);                                     # body

        $conn.send($req);        

        my $response = Zef::Grammars::HTTPResponse.new(message => $conn.recv);
        @.responses.push($response);

        if $.auto-check {
            given $response.status-code {
                when /^ 2\d+ $/ { }
                when /^301/     {
                    $response = self.request($action, ~$response.header.<Location>, $payload);
                }
                default {
                    die "[NYI] http-code: '$_'";
                }
            }
        }

        return $response;
    }

    method get(Str $url) {
        my $response = self.request('GET', $url);
        return $response;
    }

    method post(Str $url, Str $payload?) {
        my $response = self.request('POST', $url, $payload);
        return $response;
    }
}