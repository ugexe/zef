unit module Zef::Utils:JSON;

sub to-json($obj) is export {
  CATCH { default { .say; } }
  return "{$obj}"     if $obj ~~ Int;
  return "\"{$obj.subst(/'"'/, '\\"', :g)}\"" if $obj ~~ Str;

  my Str $out = '';
  if $obj ~~ Array {
    $out ~= '[';
    for @($obj) -> $i {
      $out ~= to-json($i) ~ ',';
    }
    $out .=subst(/',' $/, '');
    $out ~= ']';
  } else {
    $out ~= '{';
    for $obj.keys -> $key {
      $out ~= "\"{$key.subst(/'"'/, '\\"', :g)}\": " ~ to-json($obj{$key}) ~ ',';
    }
    $out .=subst(/',' $/, '');
    $out ~= '}';
  }
  return $out;
}
