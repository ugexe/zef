unit module Base64;


my @chars64base = flat 'A'..'Z','a'..'z','0'..'9';
my @chars64std  = chars64with('+', '/');
my @chars64uri  = chars64with('-', '_');


proto sub encode-base64(|) is export {*}
multi sub encode-base64(Str $str, |c) { samewith(Buf.new($str.ords), |c) }
multi sub encode-base64(Bool :$uri! where *.so, |c) { samewith(:alpha(@chars64uri), |c) }
multi sub encode-base64(:$pad = '=', |c) {
    die ":\$pad must be a single character (or empty) Str, or a Boolean"
        unless ($pad ~~ Str && $pad.chars == 0|1) || $pad ~~ Bool;
    callwith(:pad($pad ~~ Bool ?? ?$pad ?? '=' !! '' !! $pad), |c)
}
multi sub encode-base64(Buf $buf, :$pad, :@alpha, |c) {
    return '' unless $buf;
    my $padding   = do with (3 - $buf.bytes % 3) -> $mod { ?$pad ?? $mod == 3 ?? 0 !! $mod !! 0 }
    $buf.append(0) for ^$padding;
    my @raw = $buf.rotor(3).map: -> $chunk {
        state @encodings = chars64with(@alpha);
        my $n   = [+] @$chunk.map:    { $_ +< ((state $m = 24) -= 8) }
        my $res = (18, 12, 6, 0).map: { $n +> $_ +& 63 }
        slip(@encodings[@$res>>.item])
    }
    @raw.append($pad) for ^$padding;
    return @raw[0..(@raw.elems - $padding*2 - 1),(@raw.elems - $padding)..@raw.end].flat.join;
}

proto sub decode-base64(|) is export {*}
multi sub decode-base64(Buf $buf, |c) { samewith($buf.decode, |c) }
multi sub decode-base64(Bool :$uri! where *.so, |c) { samewith(:alpha(@chars64uri), |c) }
multi sub decode-base64(:$pad = '=', |c) {
    die ":\$pad must be a single character (or empty) Str, or a Boolean"
        unless ($pad ~~ Str && $pad.chars == 0|1) || $pad ~~ Bool;
    callwith(:pad($pad ~~ Bool ?? ?$pad ?? '=' !! '' !! $pad), |c)
}
multi sub decode-base64(Str $str, :$pad, :@alpha, |c) {
    return Buf.new unless $str;
    my @encodings = chars64with(@alpha);
    my $padding   = ?$pad ?? $str.ends-with("{$pad}{$pad}") ?? 2 !! $str.ends-with("{$pad}") ?? 1 !! 0 !! 0;
    my @chars     = $str.substr(0,*-$padding).comb(/@encodings/);
    my @raw = @chars.rotor(4, :partial).map: -> $chunk {
        state %lookup = @encodings.kv.hash.antipairs;
        my $n   = [+] $chunk.map: { (%lookup{$_} || 0) +< ((state $m = 24) -= 6) }
        my $res = (16, 8, 0).map: { $n +> $_ +& 255 }
        slip($res.grep(* > 0));
    }
    return Buf.new(@raw || 0);
}


my sub chars64with(*@chars) is cached {
    my @alpha = do with @chars.elems -> $c {
        die "alphabet contains {$c} of {$c > 2 ?? 64 !! 2} required encodings" unless $c == 0|2|64;
        $c == 64 ?? @chars !! $c == 2 ??  (@chars64base.Slip, @chars.Slip) !! @chars64std;
    }
    with @chars.grep(* ~~ none(@alpha)).Slip -> @dupes {
        die "alphabet contains {64 - @dupes.elems} of 64 required unique encodings"
            ~ "\nduplicates: {@dupes.join(',')}";
    }
    @alpha;
}

=begin pod

=encoding utf8

=head2 Base64

Base64 encoding and decoding routines

=head2 Exports

=head4 B<routine> L<encode-base64> C<$encode-me where Buf|Str, :$pad, :@alpha E<-->> Str>

    encode-base64($encode-me)
    encode-base64($encode-me, :!pad)           # No padding
    encode-base64($encode-me, :pad("*"))       # Alternative padding character
    encode-base64($encode-me, :uri)            # Use '-' and '/' for chars 63 and 64
    encode-base64($encode-me, :alpha(1..64))   # Set the entire alphabet
    encode-base64($encode-me, :alpha('-','_')) # Same as :uri

Takes a C<Buf> and applies base64 encoding with the requested options. If passed a C<Str> it will be converted to a C<Buf> via C<.ords> first.

    say encode-base64("any carnal pleasure.")
    # YW55IGNhcm5hbCBwbGVhc3VyZS4=

=head4 B<routine> L<decode-base64> C<$decode-me where Buf|Str, :$pad, :@alpha --> Buf>

    decode-base64($decode-me)
    decode-base64($decode-me, :!pad)           # No padding
    decode-base64($decode-me, :pad("*"))       # Alternative padding character
    decode-base64($decode-me, :uri)            # Use '-' and '/' for chars 63 and 64
    decode-base64($decode-me, :alpha(1..64))   # Set the entire alphabet
    decode-base64($decode-me, :alpha('-','_')) # Same as :uri

Takes a C<Str> and applies base64 decoding with the requested options. If passed a C<Buf> it will be converted to a C<Str> with C<.decode> first.

    say decode-base64("YW55IGNhcm5hbCBwbGVhc3VyZS4=")
    # any carnal pleasure.

=end pod
