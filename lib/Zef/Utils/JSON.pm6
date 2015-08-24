unit module Zef::Utils::JSON;

sub to-json($obj, Bool :$human-readable? = False, Int :$level? = 0, Int :$spacing? = 2) is export {
  CATCH { default { .say; } }
  return "{$obj}"     if $obj ~~ Int || $obj ~~ Rat;
  return "\"{$obj.subst(/'"'/, '\\"', :g)}\"" if $obj ~~ Str;

  my Str  $out = '';
  my Int  $lvl = $level;
  my Bool $arr = $obj ~~ Array;
  my $spacer   = sub {
    $out ~= "\n" ~ (' ' x $lvl*$spacing) if $human-readable;
  };

  $out ~= $arr ?? '[' !! '{';
  $lvl++;
  $spacer();
  if $arr {
    for @($obj) -> $i {
      $out ~= to-json($i, :level($level+1), :$spacing, :$human-readable) ~ ',';
      $spacer();
    }
  } else {
    for $obj.keys -> $key {
      $out ~= "\"{$key.subst(/'"'/, '\\"', :g)}\": " ~ to-json($obj{$key}, :level($level+1), :$spacing, :$human-readable) ~ ',';
      $spacer();
    }
  }
  $out .=subst(/',' \s* $/, '');
  $lvl--;
  $spacer();
  $out ~= $arr ?? ']' !! '}';
  return $out;
}
