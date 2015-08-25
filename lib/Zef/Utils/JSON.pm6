unit module Zef::Utils::JSON;

sub to-json($obj, Bool :$pretty = True, Int :$level = 0, Int :$spacing = 2) is export {
    return "{$obj}" if $obj ~~ Int|Rat;
    return "\"{$obj.subst(/'"'/, '\\"', :g)}\"" if $obj ~~ Str;

    my Int  $lvl  = $level;
    my Bool $arr  = $obj ~~ Array;
    my Str  $out ~= $arr ?? '[' !! '{';
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
            $out ~= "\"{$key.subst(/'"'/, '\\"', :g)}\": " ~ to-json($obj{$key}, :level($level+1), :$spacing, :$pretty) ~ ',';
            $spacer();
        }
    }
    $out .=subst(/',' \s* $/, '');
    $lvl--;
    $spacer();
    $out ~= $arr ?? ']' !! '}';
    return $out;
}
