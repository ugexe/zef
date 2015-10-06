unit module Base64;

my @chars64    = flat 'A'..'Z','a'..'z','0'..'9', '+', '/';
my @chars64uri = flat 'A'..'Z','a'..'z','0'..'9', '-', '_';

# todo: turn padding on/off

proto sub encode64(|) is export {*}
multi sub encode64(Str $str, |c)              { samewith(Buf.new($str.ords),  |c) }
multi sub encode64(Bool :$uri where *.so, |c) { samewith(:alpha(@chars64uri), |c) }
multi sub encode64(Buf $buf is copy, :@alpha = @chars64 --> Str) {
    return '' unless $buf;
    die "\@alpha contains only {@alpha.elems} of 64 required encodings" unless @alpha.elems == 64;
    my $padding  = do with (3 - $buf.bytes % 3) -> $mod { $mod == 3 ?? 0 !! $mod }
    $buf.append(0) for ^$padding;
    my @raw = $buf.rotor(3).map: -> $chunk {
        my $n   = [+] @$chunk.map:    { $_ +< ((state $m = 24) -= 8) }
        my $res = (18, 12, 6, 0).map: { $n +> $_ +& 63 }
        slip(@alpha[@$res>>.item])
    }
    @raw.append('=') for ^$padding;
    return @raw[0..(@raw.elems - $padding*2 - 1),(@raw.elems - $padding)..@raw.end].flat.join;
}

proto sub decode64(|) is export {*}
multi sub decode64(Buf $buf,              |c) { samewith($buf.decode,         |c) }
multi sub decode64(Bool :$uri where *.so, |c) { samewith(:alpha(@chars64uri), |c) }
multi sub decode64(Str $str, :@alpha = @chars64 --> Buf) {
    return Buf.new unless $str;
    die "\@alpha contains only {@alpha.elems} of 64 required encodings" unless @alpha.elems == 64;
    my $padding  = $str.ends-with('==') ?? 2 !! $str.ends-with('=') ?? 1 !! 0;
    my @s = $str.substr(0,*-$padding).comb(/@alpha/);
    my @raw = @s.rotor(4, :partial).map: -> $chunk {
        state %lookup = @alpha.kv.hash.antipairs;
        my $n   = [+] $chunk.map: { (%lookup{$_} || 0) +< ((state $m = 24) -= 6) }
        my $res = (16, 8, 0).map: { $n +> $_ +& 255 }
        slip($res.grep(* > 0));
    }
    return Buf.new(@raw || 0);
}
