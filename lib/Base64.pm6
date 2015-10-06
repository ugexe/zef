unit module Base64;


my @chars64base = flat 'A'..'Z','a'..'z','0'..'9';
my @chars64std  = chars64with('+', '/');
my @chars64uri  = chars64with('-', '_');
my sub chars64with(*@_) { @chars64base.Slip, @_.Slip; }

proto sub encode-base64(|) is export {*}
multi sub encode-base64(Str $str, |c) { samewith(Buf.new($str.ords), |c) }
multi sub encode-base64(Bool :$uri! where *.so, |c) { samewith(:alpha(@chars64uri), |c) }
multi sub encode-base64(Str :@alpha! where *.elems == 2, |c) { samewith(:alpha(chars64with(|@alpha)), |c) }
multi sub encode-base64(Buf $buf, :$pad = '=', :@alpha where *.unique.elems == 64 = @chars64std, |c) {
    return '' unless $buf;
    my $padding  = do with (3 - $buf.bytes % 3) -> $mod { ?$pad ?? $mod == 3 ?? 0 !! $mod !! 0 }
    $buf.append(0) for ^$padding;
    my @raw = $buf.rotor(3).map: -> $chunk {
        my $n   = [+] @$chunk.map:    { $_ +< ((state $m = 24) -= 8) }
        my $res = (18, 12, 6, 0).map: { $n +> $_ +& 63 }
        slip(@alpha[@$res>>.item])
    }
    @raw.append($pad) for ^$padding;
    return @raw[0..(@raw.elems - $padding*2 - 1),(@raw.elems - $padding)..@raw.end].flat.join;
}

proto sub decode-base64(|) is export {*}
multi sub decode-base64(Buf $buf, |c) { samewith($buf.decode, |c) }
multi sub decode-base64(Bool :$uri where *.so, |c) { samewith(:alpha(@chars64uri), |c) }
multi sub decode-base64(Str :@alpha where *.elems == 2, |c) { samewith(:alpha(chars64with(|@alpha)), |c) }
multi sub decode-base64(Str $str, :$pad = '=', :@alpha where *.unique.elems == 64 = @chars64std, |c) {
    return Buf.new unless $str;
    my $padding  = ?$pad ?? $str.ends-with("{$pad}{$pad}") ?? 2 !! $str.ends-with("{$pad}") ?? 1 !! 0 !! 0;
    my @chars = $str.substr(0,*-$padding).comb(/@alpha/);
    my @raw = @chars.rotor(4, :partial).map: -> $chunk {
        state %lookup = @alpha.kv.hash.antipairs;
        my $n   = [+] $chunk.map: { (%lookup{$_} || 0) +< ((state $m = 24) -= 6) }
        my $res = (16, 8, 0).map: { $n +> $_ +& 255 }
        slip($res.grep(* > 0));
    }
    return Buf.new(@raw || 0);
}
