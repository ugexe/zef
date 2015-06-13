use Zef::Net::HTTP;
use Zef::Net::HTTP::Dialer;

# Fill a Channel with bytes (the HTTP message body) so we 
# can process the header and possibly close the connection 
# before we would have finished receiving the body.
# Currently faked, as chunked encoding/keep alive and friends 
# break the socket inside a start {}
#
# todo: add an additional stream in case there are 
# any trailing headers.
role ByteStream {
    my $buffer;
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

    method round-trip(HTTP::Request $req --> HTTP::Response) {
        my $socket = $!dialer.dial($req.?proxy ?? $req.proxy.uri !! $req.uri);
        $socket does ByteStream;
        $socket.send($req.Str);

        my $header;
        while my $h = $socket.recv(1, :bin) {
            $header ~= $h.decode('ascii');
            last if $header.substr(*-4) eq "\r\n\r\n";
        }

        my $body = $socket.async-recv(:bin); 

        return $!responder.new(:header-chunk($header), :$body);
    }
}
