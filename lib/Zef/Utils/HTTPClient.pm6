use Zef::Grammars::HTTP;

try require IO::Socket::SSL;

# todo: * handle chunked encoding and binary
#       * test if proxy actually works
#       * use in Zef::Getter default    
#       * move proxy/basic auth into its own class
class Zef::Utils::HTTPClient {
    has $!sock;
    has $.auto-check;
    has @.responses;

    # These will be overriden for a specific request if that request
    # has these values in the url.
    has $!proxy-url;
    has $!proxy-auth-username;
    has $!proxy-auth-password;
    has $.auth-username;
    has $.auth-password;

    submethod BUILD(:$!proxy-url, :$!proxy-auth-username, :$!proxy-auth-password, :$!auto-check, :$!auth-username, :$!auth-password) { }

    submethod connect(Zef::Grammars::URI $uri) {
        my $proxy-uri = Zef::Grammars::URI.new(url => $!proxy-url) if $!proxy-url;
        my $scheme = lc($proxy-uri  ?? $proxy-uri.scheme !! ($uri.scheme // 'http'));
        my $host   =    $proxy-uri  ?? $proxy-uri.host   !! $uri.host;
        my $port   =   ($proxy-uri  ?? $proxy-uri.port   !! $uri.port) // ($scheme ~~ /^https/ ?? 443 !! 80);

        if $scheme eq 'https' && ::('IO::Socket::SSL') ~~ Failure {
            die "Please install IO::Socket::SSL for SSL support";
        }

        $!sock = ::('IO::Socket::SSL') ~~ Failure 
            ??      IO::Socket::INET.new( host => $host, port => $port )
            !! ($scheme ~~ /^https/ 
                    ?? ::('IO::Socket::SSL').new( host => $host, port => $port )
                    !! IO::Socket::INET.new( host => $host, port => $port )    );
    }

    method request($action, $url, :$payload) {
        my $request = Zef::Grammars::HTTPRequest.new(
            :$action, :$url, :$payload, 
            :$!auth-username,
            :$!auth-password, 
            :$!proxy-auth-username, 
            :$!proxy-auth-password
        );
        my $conn    = self.connect($request.uri);

        $conn.send(~$request);

        my $response = Zef::Grammars::HTTPResponse.new(message => $conn.recv);
        @.responses.push($response);

        if $.auto-check {
            given $response.status-code {
                when /^ 2\d+ $/ { }
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
        my $response = self.request('GET', $url);
        return $response;
    }

    method post(Str $url, Str $payload?) {
        my $response = self.request('POST', $url, :$payload);
        return $response;
    }
}