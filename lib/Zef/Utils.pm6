class Zef::Utils;

has $.path;

method dir($dir = $.path, Bool :$f, Bool :$d, Bool :$r) {
    my @results;
    my $paths = Supply.from-list( dir($dir) );

    $paths.grep(*.d).tap(-> $dir-path { 
        @results.push($dir-path);
    }) if $d;

    $paths.grep(*.f).tap(-> $file-path { 
        @results.push($file-path);
    }) if $f;

    $paths.grep(*.d).tap(-> $dir-path {
        $paths.emit($_) for dir($dir-path);
    }) if $r;

    return @results;
}

method comb($dir = $.path) {
  die "$dir does not exist" unless $dir.IO ~~ :d;
  my @minimeta;
  my @files = self.dir($dir, :f, :r);
  my $slash = / [ '/' | '\\' ]  /;
  for @files -> $f {
    my @depends;
    for $f.slurp -> $t is copy {
      while $t ~~ /^^ \s* '=begin' \s+ <ident> .* '=end' \s+ <ident> / {
        $t = $t.substr(0,$/.from) ~ $t.substr($/.to);
      }
      for $t.lines -> $l {
        if $l ~~ /^ \s* ['use'||'need'||'require'] \s+ (\w+ ['::' \w+]*)/ {
          @depends.push($0.Str) if $0 !~~ any ('MONKEY_TYPING', 'v6');
        }
      }
    }
    @minimeta.push({
      name => $f.path.subst(/^"{$dir.Str}"<$slash>/,'').subst(/^'lib'<$slash>/, '').subst(/^'lib6'<$slash>/, '').subst(/\.pm6?$/, '').subst($slash, '::', :g),
      file => $f.path,
      dependencies => @depends, 
    });
  }

  return @(@minimeta);
}


my @b64chars = qw<A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 + />;

multi method b64encode(Buf $s is copy) {
  my $r = '';
  my $p = '';
  my $c = $s.elems % 3;
  my (@n,$n);

  while $c < 3 && $c != 0 {
    $p ~= '=';
    $s ~= Buf.new(0);
    $c++;
  }

  $c = 0;
  while $c < $s.elems {
    $n = ($s[$c] +< 16) + ($s[$c+1] +< 8) + $s[$c+2];
    @n = ($n +> 18) +& 63, ($n +> 12) +& 63, ($n +> 6) +& 63, $n +& 63;
    $r ~= @n.map({ @b64chars[$_]; }).join;

    $c += 3;
  }

  return $r.substr(0, *-$p.chars) ~ $p;
}

multi method b64encode(Str $s) {
  self.b64encode(Buf.new($s.encode('utf8')));
}

method b64decode(Str $string, Bool :$decode = False) {
  return Buf.new unless $string;
  my $padding = $string.comb(/'='?'='$/).chars;
  my Str @s   = $string.substr(0,*-$padding).comb;
  my @r = gather for @s.rotor(4, :partial) -> $chunk {
    my $n <<+=>> $chunk.list.map({ @b64chars.first-index($_) +< ((state $m = 24) -= 6) });
    take $_ for (16, 8, 0).map({ (($n +> $_) +& 255) }).grep(* > 0);
  }
  return Buf.new(@r);
}
