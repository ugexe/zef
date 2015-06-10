use Zef::Net::HTTP::Request;
try require IO::Socket::SSL;

role Zef::Net::HTTP::Transport {
    has $.can-ssl = !::("IO::Socket::SSL").isa(Failure);

    class ByteStream {
        has Promise $.promise;
        has Channel $.buffer;

        submethod BUILD(:$socket) {
            $!buffer  = Channel.new;
            $!promise = Promise.anyof(
                $!buffer.closed,
                Promise.in(30),
                start {
                    while my $b = $socket.recv(:bin) {
                        $!buffer.send($b);
                    }
                    $!buffer.close;
                }
            );
        }
    }

    method dial(Zef::Net::HTTP::Request:D:) {
        my $uri  := $.uri;
        my $puri := $.proxy.uri if $.proxy.?uri;

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

    method go(Zef::Net::HTTP::Request:D:) {
        my $socket = $.dial;
        $socket.send($.Str);

        my $header;
        while my $h = $socket.recv(1, :bin) {
            $header ~= $h.decode('ascii');
            last if $header.substr(*-4) eq "\r\n\r\n";
        }

        my $body = ByteStream.new(:$socket);
        # todo: this should return an interface implementation
        return %(:$header, :$body);
    }
}
