use Zef::Net::HTTP;
use Zef::Net::HTTP::Dialer;

# Mimick Async with IO::Socket::INET/IO::Socket::SSL
role ByteStream {
    my $buffer;

    # Fill a Channel with bytes (the HTTP message body) so we 
    # can process the header and possibly close the connection 
    # before we would have finished receiving the body.
    # Currently faked, as chunked encoding/keep alive and friends 
    # break the socket inside a start {}.
    #
    # todo: add an additional stream in case there are 
    # any trailing headers.
    method async-recv(|c, Bool :$bin) {
        $buffer = Channel.new;

        my $promise = Promise.anyof(
            $buffer.closed,
            Promise.in(30),
            do {
                my $promise = Promise.new;
                my $vow = $promise.vow;
#            start {
                while $.recv(|c, :$bin) -> $b {
                    $buffer.send($b);
                }
#            }.then({ 
                $buffer.close;
                $vow.keep($promise);
#            });
            }
        );

        return $promise => $buffer;
    }
}

# Manage connections (caching, proxies)
class Zef::Net::HTTP::Transport does HTTP::RoundTrip {
    has HTTP::Dialer   $.dialer;
    has HTTP::Response $.responder;

    submethod BUILD(HTTP::Dialer :$!dialer, HTTP::Response :$!responder) {
        $!dialer = Zef::Net::HTTP::Dialer.new unless $!dialer;
    }

    # A HTTP::RoundTrip that returns an HTTP::Response once the header 
    # has been received, and a Promise that will be kept once it fills 
    # Channels ($.body/$.trailer-chunk) with the optional body and/or trailer data
    method round-trip(HTTP::Request $req --> HTTP::Response) {
        my $socket = $!dialer.dial($req.?proxy ?? $req.proxy.uri !! $req.uri);
        $socket does ByteStream;
        $socket.send: $req.DUMP(:start-line);
        $socket.send: $req.DUMP(:headers);

        # todo: the body may be text or binary so we need to choose between 
        # .send and .write accordingly. We could also try to do the encoding 
        # ourselves This happens behind the scenes with .send/.write, and they 
        # do it with nqp ops, so by not encoding ourselves we avoid the speed 
        # penalty of pure perl6 code and having any extra nqp code in our codebase.
        $socket.send: $req.DUMP(:body);

        $socket.send: $req.DUMP(:trailers);

        # ?: should we allow cancelation of the receiving socket (not including
        # timeout related canceling) before it has finished reading the header?
        my $header;
        while my $h = $socket.recv(1, :bin) {
            $header ~= $h.decode('ascii');
            last if $header.substr(*-4) eq "\r\n\r\n";
        }

        # $body is a Channel that will receive the data as it arrives in a 
        # non-blocking fashion. This means we can return the HTTP::Request 
        # back to the user to process the headers and possibly close the connection
        # before all of $body has been received.
        my $body = $socket.async-recv(:bin);

        # my $trailer = $socket.async-recv(:bin);

        return $!responder.new(:header-chunk($header), :$body); #, :$trailer);
    }
}
