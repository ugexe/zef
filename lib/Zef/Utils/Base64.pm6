class Zef::Utils::Base64;

has @.b64chars = qw<A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 + />;
has Bool $.is-url; # not fully implemented 
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
    return '' unless $encode-me;
    my @r = gather for $encode-me.rotor(3, :partial) -> $chunk {
        my $n <<+=>> $chunk.map({ $_ +< ((state $m = 24) -= 8) });
        my @res = (18, 12, 6, 0).map({ (($n +> $_) +& 63) }).map({ @.b64chars[$_] });
        for @res -> $r { take $r };
        LAST { given $chunk.elems { take '=','=' when 1; take '=' when 2; } }
    }
    my $padding = @r[*-2..*].join.comb(/'='?'='$/).chars;
    return $.encoded = @r[0..(@r.elems - $padding*2 - 1),(@r.elems - $padding)..*].join;
}

method b64decode(Str $decode-me = $.encoded) {
    return Buf.new unless $decode-me;
    my $padding = $decode-me.comb(/'='?'='$/).chars;
    my Str @s   = $decode-me.substr(0,*-$padding).comb;
    my @r = gather for @s.rotor(4, :partial) -> $chunk {
        my $n <<+=>> $chunk.map({ @.b64chars.first-index($_) +< ((state $m = 24) -= 6) });
        my @res = (16, 8, 0).map({ (($n +> $_) +& 255) }).grep(* > 0);
        take $_ for @res;
    }
    return $.decoded = Buf.new(@r.elems ?? @r !! 0);
}


sub b64decode(Str $decode-me) is export(:DEFAULT) {
    Zef::Utils::Base64.new.b64decode($decode-me);
}

sub b64encode($encode-me where Buf|Str) is export(:DEFAULT) {
    Zef::Utils::Base64.new.b64encode($encode-me);
}


