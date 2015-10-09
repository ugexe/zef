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
multi sub encode-base64(Buf $buf, :$pad, :@alpha, Bool :$seq = False, |c) {
    return '' if !$buf && !$seq;
    my $raw = $buf.rotor(3, :partial).map: -> $chunk {
        state $encodings = chars64with(@alpha);
        state $padding = 0;
        my $n = [+] ($chunk.map({
                state $count += 1;
                LAST { $padding = do with (3 - $count % 3) { ?$pad ?? $^a == 3 ?? 0 !! $^a !! 0 } }
                $_ +< ((state $m = 24) -= 8)
            }).Slip, ((0 x $padding).Slip if $padding)).Slip;
        my $res = (18, 12, 6, 0).map: { $n +> $_ +& 63 }
        (slip($encodings[$res>>.item][0..*-($padding == 2 ?? 3 !! $padding == 1 ?? 2 !! 0)]), 
            ((^$padding).map({"$pad"}).Slip if $padding)).Slip;
    }
    ?$seq ?? $raw !! $raw.join;
}

proto sub decode-base64(|) is export {*}
multi sub decode-base64(Buf $buf, |c) { samewith($buf.decode, |c) }
multi sub decode-base64(Bool :$uri! where *.so, |c) { samewith(:alpha(@chars64uri), |c) }
multi sub decode-base64(:$pad = '=', |c) {
    die ":\$pad must be a single character (or empty) Str, or a Boolean"
        unless ($pad ~~ Str && $pad.chars == 0|1) || $pad ~~ Bool;
    callwith(:pad($pad ~~ Bool ?? ?$pad ?? '=' !! '' !! $pad), |c)
}
multi sub decode-base64(Str $str, :$pad, :@alpha, Bool :$seq = False, |c) {
    return Buf.new unless $str;
    my $encodings = chars64with(@alpha);
    my $raw = $str.comb(/@$encodings/).rotor(4, :partial).map: -> $chunk {
        state %lookup = $encodings.kv.hash.antipairs;
        my $n   = [+] $chunk.map: { (%lookup{$_} || 0) +< ((state $m = 24) -= 6) }
        my $res = (16, 8, 0).map: { $n +> $_ +& 255 }
        slip($res.grep(* > 0));
    }
    ?$seq ?? $raw !! Buf.new($raw || 0);
}


my sub chars64with(*@chars) is cached {
    my @alpha = do with @chars.elems -> $c {
        die "alphabet contains {$c} of {$c > 2 ?? 64 !! 2} required encodings" unless $c == 0|2|64;
        $c == 64 ?? @chars !! $c == 2 ??  (@chars64base.Slip, @chars.Slip) !! @chars64std;
    }
    if @chars.grep(* ~~ none(@alpha)) -> $dupes {
        die "alphabet contains {64 - $dupes.elems} of 64 required unique encodings"
            ~ "\nduplicates: {$dupes.join(',')}";
    }
    @alpha;
}
