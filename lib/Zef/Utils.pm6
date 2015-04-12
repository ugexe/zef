class Zef::Utils;

method comb($dir) {
  die "$dir does not exist" unless $dir.IO ~~ :d;
  my @minimeta;
  my @files = @($.ls($dir));
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

method ls($dir) {
  my @files;
  for $dir.IO.dir -> $f {
    @files.push($.ls($f).list), next if $f ~~ :d;
    @files.push($f) if $f ~~ / '.pm' '6'? $ /;
  }
  return @files;
}

my @b64chars = qw<A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 + />;
my $b64charsi = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
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

method b64decode(Str $s is copy, Bool :$decode = False) {
  my @p = $s.split('');
  my @s = @p.grep(-> $c { 
    @b64chars.grep({ $_ eq $c }) || $c eq '=' 
  }); 
  my $l = 0;
  for (@s.elems - 2) .. (@s.elems - 1) {
    last if $_ < 0 || $_ >= @s.elems;
    next if @s[$_] ne '=';
    $l++;
    @s[$_] = 'A';
  }
  
  my $p = '';
  my Buf $r .= new;
  my $c = 0;
  my $n;
  while $c < @s.elems {
    $n = ($b64charsi.match(@s[$c]).from +< 18) + 
         ($b64charsi.match(@s[$c+1]).from +< 12) +
         ($b64charsi.match(@s[$c+2]).from +< 6) +
         ($b64charsi.match(@s[$c+3]).from); 
    $r ~= Buf.new(($n +> 16) +& 255)
        ~ Buf.new(($n +> 8) +& 255)
        ~ Buf.new($n +& 255);
    $c += 4;
  }
  try return Buf.new($r.subbuf(0, $r.elems-$l)).decode if $decode;
  return $r.subbuf(0, $r.elems-$l);
}
