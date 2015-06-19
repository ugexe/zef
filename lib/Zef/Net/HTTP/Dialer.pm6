use Zef::Net::HTTP;
try require IO::Socket::SSL;

class Zef::Net::HTTP::Dialer does HTTP::Dialer {
    has $.can-ssl = !::("IO::Socket::SSL").isa(Failure);

    method dial(HTTP::URI $uri) {
        my $scheme = $uri.scheme // 'http';
        my $host   = $uri.host;
        my $port   = $uri.port // ($scheme eq 'https' ?? 443 !! 80);

        my $client-socket = IO::Socket::INET.new( :$host, :$port );

        given $scheme {
            when 'http' {
                return $client-socket;
            }
            when 'https' {
                unless $!can-ssl {
                    die "Please install IO::Socket::SSL to use https";
                }
                return ::('IO::Socket::SSL').new( :$client-socket );
            }
            default {
                die "Scheme: '$scheme' is NYI";
            }
        }
    }
}