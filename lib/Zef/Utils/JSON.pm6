unit module Zef::Utils::JSON;

sub str-escape(str $text) {
  return $text.subst(/'\\'/, '\\\\', :g)\
              .subst(/"\n"/, '\\n',  :g)\
              .subst(/"\r"/, '\\r',  :g)\
              .subst(/"\t"/, '\\t',  :g)\
              .subst(/'"'/,  '\\"',  :g);
}

sub to-json($obj, Bool :$pretty = True, Int :$level = 0, Int :$spacing = 2) is export {
    return "{$obj}" if $obj ~~ Int|Rat;
    return "{$obj ?? 'true' !! 'false'}" if $obj ~~ Bool;
    return "\"{str-escape($obj)}\"" if $obj ~~ Str;

    my int  $lvl  = $level;
    my Bool $arr  = $obj ~~ Array;
    my str  $out ~= $arr ?? '[' !! '{';
    my $spacer   := sub {
        $out ~= "\n" ~ (' ' x $lvl*$spacing) if $pretty;
    };

    $lvl++;
    $spacer();
    if $arr {
        for @($obj) -> $i {
          $out ~= to-json($i, :level($level+1), :$spacing, :$pretty) ~ ',';
          $spacer();
        }
    }
    else {
        for $obj.keys -> $key {
            $out ~= "\"{$key ~~ Str ?? str-escape($key) !! $key}\": " ~ to-json($obj{$key}, :level($level+1), :$spacing, :$pretty) ~ ',';
            $spacer();
        }
    }
    $out .=subst(/',' \s* $/, '');
    $lvl--;
    $spacer();
    $out ~= $arr ?? ']' !! '}';
    return $out;
}
