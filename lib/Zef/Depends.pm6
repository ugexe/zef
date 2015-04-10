class Zef::Depends;

method build(@metas is copy) {
  my @tree;

  my $visit = sub ($meta is rw, $from? = '') {
    return if ($meta<marked> // 0) == 1; 
    if ($meta<marked> // 0) == 0 {
      $meta<marked> = 1;
      for @($meta<dependencies>) -> $m {
        for @metas.grep({ $_<name> eq $m }) -> $m2 {
          $visit($m2, $meta<name>);
        }
      }
      $meta<marked> = 2;
      @tree.push($meta);
    }
  };

  my $i = 0;
  for @metas -> $meta {
    $visit($meta, 'olaf') if ($meta<marked> // 0) == 0;
  }

  return @tree;
}

method ls($dir) {
  my @files;
  for $dir.IO.dir -> $f {
    @files.push($.ls($f).list), next if $f ~~ :d;
    @files.push($f) if $f ~~ / '.pm' '6'? $ /;
  }
  return @files;
}

method compress(@tree is copy) {
  my @ctree;
  my ($i, $level) = 0, 0;
  for @tree -> $n {
    for $i == 0 ?? () !! @tree[0..$i-1] -> $l {
      $level++ if $n<dependencies>.grep($l<name>);
    }
    while $level > @ctree.elems {
      @ctree.push([]);
    }
    @ctree[$level].push($n);
    $i++;
    $level = 0;
  }

  return @ctree.grep({ $_.elems > 0 });
}

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

  return @($.build(@minimeta));
}
