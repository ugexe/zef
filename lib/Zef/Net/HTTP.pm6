my class Zef::Net::HTTP { }

role HTTP::Request {
    method Str { ... }
    method url { ... }
    method uri { ... }
}

role HTTP::Response {
    method status-code  { ... }
    method header-chunk { ... }
    method body         { ... }
}

role HTTP::URI {
    method scheme { ... }
    method host   { ... }
    method port   { ... }
}

# Interface for returning different IO::Socket subclasses
role HTTP::Dialer {
    method dial(HTTP::URI $uri --> IO::Socket) { ... }
}

# Interface for sending a single request and getting a single response
role HTTP::RoundTrip {
    method round-trip(HTTP::Request $req --> HTTP::Response) { ... }
}


# decode a chunked buffer (ignores extensions)
sub ChunkedReader(buf8 $buf) is export(:DEFAULT) {
    my @data;
    my $i = 0;

    loop {
        my $size-line;
        loop {
            $size-line ~= $buf.subbuf($i++,1).decode('latin-1');
            last if $size-line ~~ /^\d+ [';' .*?]? \r\n/;
        }
        my $size = :16($size-line.substr(0,*-2));
        last if $size == 0;
        @data.push: $buf.subbuf($i,$size);
        $i += $size + 2;
        last if $i == $buf.bytes;
    }

    my buf8 $r = @data.reduce(-> $a is copy, $b { $a ~= $b });
    return $r;
}
