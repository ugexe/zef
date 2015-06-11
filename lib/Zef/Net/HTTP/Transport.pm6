use Zef::Net::HTTP::Request;
try require IO::Socket::SSL;

# Fill a Channel with bytes (the HTTP message body) so we 
# can process the header and possibly close the connection 
# before we would have finished receiving the body.
role ByteStream {
    my $buffer;
    method async-recv(|c, Bool :$bin) {
        $buffer = Channel.new;

        my $promise = Promise.anyof(
            $buffer.closed,
            Promise.in(30),
            start {
                while my $b = $.recv(|c :$bin) {
                    $buffer.send($b);
                }
            }.then({ $buffer.close });
        );

        return $promise => $buffer;
    }
}

# Manage connections (caching, proxies)
role Zef::Net::HTTP::Transport {
    has $.can-ssl = !::("IO::Socket::SSL").isa(Failure);

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
        $socket does ByteStream;
        $socket.send($.Str);

        my $header;
        while my $h = $socket.recv(1, :bin) {
            $header ~= $h.decode('ascii');
            last if $header.substr(*-4) eq "\r\n\r\n";
        }

        my $body = $socket.async-recv(:bin); #ByteStream.new(:$socket);
        # todo: this should return an interface implementation
        return %(:$header, :$body);
    }
}
