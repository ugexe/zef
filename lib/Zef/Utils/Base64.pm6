class Zef::Utils::Base64 {
    has @.b64chars;
    has Bool $.is-url;
    has $.encoded is rw;
    has $.decoded is rw;

    submethod BUILD(Bool :$!is-url?) {
        @!b64chars = flat 'A'..'Z','a'..'z','0'..'9', $!is-url ?? <- _> !! <+ />;
    }

    multi method b64encode(Str $encode-me) {
        my Buf $buf = Buf.new($encode-me.encode);
        self.b64encode($buf);
    }

    multi method b64encode(Buf $encode-me is copy = $.decoded) {
        return '' unless $encode-me;
        my @r = gather for $encode-me.rotor(3, :partial) -> $chunk {
            my $n   = [+] $chunk.map:     { $_ +< ((state $m = 24) -= 8) }
            my @res = (18, 12, 6, 0).map: { $n +> $_ +& 63 }
            take $_ for @!b64chars[@res].grep(*.so);
            LAST { take '=' for ^(3 - $chunk.elems) }
        }
        my $padding = @r[*-1] eq '=' ?? @r[*-2] eq '=' ?? 2 !! 1 !! 0;
        return $.encoded = @r[0..(@r.elems - $padding*2 - 1),(@r.elems - $padding)..@r.end].flat.join;
    }

    method b64decode(Str $decode-me = $.encoded) {
        return Buf.new unless $decode-me;
        my $padding = $decode-me.ends-with('==') ?? 2 !! $decode-me.ends-with('=') ?? 1 !! 0;
        my @s = do with @!b64chars -> $c { $decode-me.substr(0,*-$padding).comb(/@$c/) }
        my @r = gather for @s.rotor(4, :partial) -> $chunk {
            my $n   = [+] $chunk.map: { (@!b64chars.first-index($_) // 0) +< ((state $m = 24) -= 6) }
            my @res = (16, 8, 0).map: { $n +> $_ +& 255 }
            take $_ for @res.grep(* > 0);
        }
        return $.decoded = Buf.new(@r || 0);
    }
}

sub b64decode(Str $decode-me) is export(:DEFAULT) {
    Zef::Utils::Base64.new.b64decode($decode-me);
}

sub b64encode($encode-me where Buf|Str) is export(:DEFAULT) {
    Zef::Utils::Base64.new.b64encode($encode-me);
}


