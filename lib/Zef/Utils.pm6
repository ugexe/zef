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

