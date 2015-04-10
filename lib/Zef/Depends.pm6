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
