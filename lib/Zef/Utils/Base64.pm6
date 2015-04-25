class Zef::Utils::Base64;

has @.b64chars = qw<A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 + />;
has Bool $.is-url;
has $.encoded is rw;
has $.decoded is rw;

submethod BUILD(Bool :$!is-url?) {
    if $!is-url {
        @!b64chars[*-2] = '-';
        @!b64chars[*-1] = '_';
    }
}

multi method b64encode(Str $encode-me) {
    my Buf $buf = Buf.new($encode-me.encode);
    self.b64encode($buf);
}

multi method b64encode(Buf $encode-me is copy = $.decoded) {
    my $r = '';
    my $p = '';
    my $c = $encode-me.elems % 3;
    my (@n,$n);

    while $c < 3 && $c != 0 {
        $p ~= '=';
        $encode-me ~= Buf.new(0);
        $c++;
    }

    $c = 0;
    while $c < $encode-me.elems {
        $n = ($encode-me[$c] +< 16) + ($encode-me[$c+1] +< 8) + $encode-me[$c+2];
        @n = ($n +> 18) +& 63, ($n +> 12) +& 63, ($n +> 6) +& 63, $n +& 63;
        $r ~= @n.map({ @.b64chars[$_]; }).join;

        $c += 3;
    }

    return $r.substr(0, *-$p.chars) ~ $p;
}

method b64decode(Str $decode-me = $.encoded) {
    return Buf.new unless $decode-me;
    my $padding = $decode-me.comb(/'='?'='$/).chars;
    my Str @s   = $decode-me.substr(0,*-$padding).comb;
    my @r = gather for lol |@s.rotor(4, :partial) -> $chunk {
        my $n <<+=>> $chunk.list.map({ @.b64chars.first-index($_) +< ((state $m = 24) -= 6) });
        take $_ for (16, 8, 0).map({ (($n +> $_) +& 255) }).grep(* > 0);
    }
    return $.decoded = Buf.new(@r.elems ?? @r !! 0);
}


sub b64decode(Str $decode-me) is export(:DEFAULT) {
    Zef::Utils::Base64.new.b64decode($decode-me);
}

sub b64encode($encode-me where Buf|Str) is export(:DEFAULT) {
    Zef::Utils::Base64.new.b64encode($encode-me);
}