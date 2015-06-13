use Zef::Net::HTTP;
try require IO::Socket::SSL;

class Zef::Net::HTTP::Dialer does HTTP::Dialer {
    has $.can-ssl = !::("IO::Socket::SSL").isa(Failure);

    method dial(HTTP::URI $uri) {
        my $scheme = $uri.scheme // 'http';
        my $host   = $uri.host;
        my $port   = $uri.port // ($scheme eq 'https' ?? 443 !! 80);

        my $socket = do given $scheme {
            when 'https' {
                $!can-ssl 
                    ?? ::('IO::Socket::SSL').new( :$host, :$port )
                    !! die "Please install IO::Socket::SSL for SSL support";
            }

            when 'http' {
                IO::Socket::INET.new( :$host, :$port );
            }

            default {
                die "Scheme: '$scheme' is NYI";
            }
        }

        $socket;
    }
}