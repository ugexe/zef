use Zef::Net::HTTP;
try require IO::Socket::SSL;

class Zef::Net::HTTP::Dialer does HTTP::Dialer {
    method can-ssl { state $ssl = !::("IO::Socket::SSL").isa(Failure) }

    method dial(HTTP::URI $uri) {
        my $scheme = $uri.scheme // 'http';
        my $host   = $uri.host;
        my $port   = $uri.port // ($scheme eq 'https' ?? 443 !! 80);

        my $client-socket = IO::Socket::INET.new( :$host, :$port );

        given $scheme {
            when 'https' {
                die "Please install IO::Socket::SSL to use https" unless self.can-ssl;
                return ::('IO::Socket::SSL').new( :$client-socket );
            }
            when 'http'  { return $client-socket          }
            default      { die "Scheme: '$scheme' is NYI" }
        }
    }
}