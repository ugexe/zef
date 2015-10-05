unit module Base64;

my %chars64 = ('A'..'Z','a'..'z','0'..'9', '+', '/').flat.kv;

proto sub encode64(|) is export {*}
multi sub encode64(Str $str) { samewith(Buf.new($str.encode)) }
multi sub encode64(Buf $buf) {
    return '' unless $buf;
    my $padding = 0;
    my @raw = $buf.rotor(3, :partial).map: -> $chunk {
        my $n   = [+] $chunk.map:     { $_ +< ((state $m = 24) -= 8) }
        my $res = (18, 12, 6, 0).map: { $n +> $_ +& 63 }
        slip( %chars64{$res>>.item}.grep(*.so).Slip, (('=' for ^($padding = 3 - $chunk.elems)).Slip) )
    }
    return @raw[0..(@raw.elems - $padding*2 - 1),(@raw.elems - $padding)..@raw.end].flat.join;
}

proto sub decode64(|) is export {*}
multi sub decode64(Buf $buf) { samewith($buf.decode) }
multi sub decode64(Str $str) { 
    return Buf.new unless $str;
    my $padding = $str.ends-with('==') ?? 2 !! $str.ends-with('=') ?? 1 !! 0;
    my @s = do with @(%chars64.values) -> $c { $str.substr(0,*-$padding).comb(/@$c/) }
    my @raw = @s.rotor(4, :partial).map: -> $chunk {
        my $n   = [+] $chunk.map: { (%(%chars64.antipairs){$_} || 0) +< ((state $m = 24) -= 6) }
        my $res = (16, 8, 0).map: { $n +> $_ +& 255 }
        slip($res.grep(* > 0));
    }
    return Buf.new(@raw || 0);
}
