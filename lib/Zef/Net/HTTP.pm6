my class Zef::Net::HTTP { }

role HTTP::Request {
    method start-line { ... }
    method header     { ... }
    method body       { ... }
    method trailer    { ... }

    method url { ... }
    method uri { ... }
}

role HTTP::Response {
    method status-code  { ... }
    method header       { ... }
    method body         { ... }
}

role HTTP::URI {
    method scheme { ... }
    method host   { ... }
    method port   { ... }
}

# Interface for returning different IO::Socket subclasses
role HTTP::Dialer {
    method dial(HTTP::URI $uri) { ... }
}

# Interface for sending a single request and getting a single response
role HTTP::RoundTrip {
    method round-trip(HTTP::Request $req --> HTTP::Response) { ... }
}


role HTTP::BufReader {
    method header-supply {
        supply {
            my @crlf;
            my @sep = 13, 10, 13, 10;
            while $.recv(1, :bin) -> \data {
                my $d = buf8.new(data).decode('latin-1');
                @crlf.push(data.contents);
                emit($d);
                @crlf.shift if @crlf.elems > 4;
                last if @crlf ~~ @sep;
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

# decode a chunked buffer (ignores extensions)
sub ChunkedReader(buf8 $buf) is export(:DEFAULT) {
    my @data;
    my $i = 0;

    loop {
        my $size-line;
        loop {
            last if $i == $buf.bytes;
            $size-line ~= $buf.subbuf($i++,1).decode('latin-1');
            last if $size-line ~~ /\r\n/;
        }
        my $size = :16($size-line.substr(0,*-1)); # -1 because \r\n is 1 now, but only for string... or something
        last if $size == 0;
        @data.push: $buf.subbuf($i,$size);
        $i += $size + 2; # 1) \r 2) \n
        last if $i == $buf.bytes;
    }

    my buf8 $r = @data.reduce(-> $a is copy, $b { $a ~= $b });
    return $r;
}
