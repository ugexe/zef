use Zef::Net::HTTP;
use Zef::Net::HTTP::Dialer;

# Mimick Async with IO::Socket::INET/IO::Socket::SSL
role ByteStream {
    my $buffer;

    method async-recv(|c, Bool :$bin) {
        $buffer = Channel.new;

        my $promise = Promise.new;
        my $vow = $promise.vow;
#            start {
        while $.recv(|c, :$bin) -> $b {
            $buffer.send($b);
        }
#            }.then({ 
        $buffer.close;
        $.close;
        $vow.keep($buffer);
#            });
    }
}

# Manage connections (caching, proxies)
class Zef::Net::HTTP::Transport does HTTP::RoundTrip {
    has HTTP::Dialer   $.dialer;
    has HTTP::Response $.responder;

    submethod BUILD(HTTP::Dialer :$!dialer, HTTP::Response :$!responder) {
        $!dialer := Zef::Net::HTTP::Dialer.new unless $!dialer;
    }

    # A HTTP::RoundTrip that returns an HTTP::Response once the header 
    # has been received, and a Promise that will be kept once it fills 
    # Channels ($.body/$.trailer-chunk) with the optional body and/or trailer data
    method round-trip(HTTP::Request $req --> HTTP::Response) {
        fail "HTTP Scheme not supported: {$req.uri.scheme}" 
            unless $req.uri.scheme ~~ any(<http https>);

        my $t = $req.DUMP(:start-line);
        $t   ~= $req.DUMP(:headers);

        my $socket := $!dialer.dial($req.?proxy ?? $req.proxy.uri !! $req.uri);
        $socket does ByteStream;;
        $socket.send: $req.DUMP(:start-line);
        $socket.send: $req.DUMP(:headers);

        given $req.body {
            when *.not { #`<no body in request; skip this> }

            when Buf { $socket.write($_) }
            when Str { $socket.send($_)  }

            default {
                die "{::?CLASS} doesn't know how to handle :\$body of this type: {$_.perl}";
            }
        }

        $socket.send: $req.DUMP(:trailers);

        # ?: should we allow cancelation of the receiving socket (not including
        # timeout related canceling) before it has finished reading the header?
        my $header;
        while my $h := $socket.recv(1, :bin) {
            $header ~= $h.decode('ascii');
            last if $header.substr(*-4) eq "\r\n\r\n";
        }

        # $body is a Channel that will receive the data as it arrives in a 
        # non-blocking fashion. This means we can return the HTTP::Request 
        # back to the user to process the headers and possibly close the connection
        # before all of $body has been received.
        my $body := $socket.async-recv(:bin);

        # my $trailer = $socket.async-recv(:bin);

        return $!responder.new(:$header, :$body); #, :$trailer);
    }
}
