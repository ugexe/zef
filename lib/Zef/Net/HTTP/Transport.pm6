use Zef::Net::HTTP;
use Zef::Net::HTTP::Dialer;

role HTTP::BufReader {
    method header-supply {
        supply {
            state @crlf;
            while $.recv(1, :bin) -> \data {
                my $d = buf8.new(data).decode('latin-1');
                @crlf.push($d);
                emit($d);
                @crlf.shift if @crlf.elems > 4;
                last if @crlf ~~ ["\r", "\n", "\r", "\n"];
            }
            done();
        }
    }
    method body-supply {
        supply {
            while $.recv(:bin) -> \data {
                my $d = buf8.new(data);
                emit($d);
            }
            done();
        }
    }
    method trailer-supply { }
}

# Manage connections (caching, proxies)
class Zef::Net::HTTP::Transport does HTTP::RoundTrip {
    has HTTP::Dialer   $.dialer;
    has HTTP::Response $.responder;

    submethod BUILD(HTTP::Dialer :$!dialer, HTTP::Response :$!responder) {
        $!dialer = Zef::Net::HTTP::Dialer.new unless $!dialer;
    }

    method round-trip(HTTP::Request $req --> HTTP::Response) {
        fail "HTTP Scheme not supported: {$req.uri.scheme}" 
            unless $req.uri.scheme ~~ any(<http https>);

        my $t = $req.DUMP(:start-line);
        $t   ~= $req.DUMP(:headers);

        my $socket = $!dialer.dial($req.?proxy ?? $req.proxy.uri !! $req.uri);

        $socket does HTTP::BufReader;
        $socket.print: $req.DUMP(:start-line);
        $socket.print: $req.DUMP(:headers);

        given $req.body {
            when *.not { #`<no body in request; skip this> }

            when Buf { $socket.write($_) }
            when Str { $socket.print($_) }

            default {
                die "{::?CLASS} doesn't know how to handle :\$body of this type: {$_.perl}";
            }
        }

        $socket.print: $req.DUMP(:trailers);

        # attempt to provide separate supply for header and body
        my $header-supply = $socket.header-supply;
        my $body-supply   = $socket.body-supply;


        # For now we return header as a string so that $body will not be tapped before the header.
        # However will be changed so the header is returned as a supply as well, and body will set
        # the $header supply appropriately.
        return $!responder.new(:header($header-supply.join), :body($body-supply)); #, :$trailer);
    }
}
