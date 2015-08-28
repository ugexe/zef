role Zef::Distribution {
    has $.name;
    has $.authority;
    has $.version;


    # todo: something similar that checks cver to know when to rebuild
    method is-installed(*@curlis is copy) {
        @curlis := @curlis ?? @curlis !! $.curlis;
        my $want-n := self.name or fail "A distribution must have a name";
        my $want-a := self.authority;
        my $want-v := Version.new(self.version).Str;

        gather for @curlis -> $curli {
            for $curli.candidates($want-n).list -> $have {
                my $have-n = $have<name> or next;
                my $have-a = $have<auth> || "{$have<authority> || ''}:{$have<author> || ''}";
                my $have-v = Version.new($have<ver> || $have<version> || '*').Str;
                next unless $have-n.lc eq $want-n.lc
                        ||  $have-a.lc eq $want-a.lc
                        ||  ($have-v.lc eq $want-v.lc || $want-v eq '*');
                take $curli;
            }
        }
    }

    method candidates(::CLASS:D:) { flat $.curlis.map: {.candidates($.name, :auth($.authority), :ver($.version)).grep(*)} }

    method wanted(:$take-whatever = True) {
        return True  if  $.version eq '*' && $take-whatever;
        return False if $.candidates.first({ $.VCOMPARE($_.<ver>.Str) ~~ any(Order::Same, Order::Less) });
        return True;
    }

    method metainfo         { $.meta }
    method VCOMPARE($other) { VCOMPARE($.version, $other) }

    method content {...}
    method meta    {...}
}

sub VCOMPARE($v1, $v2) is export {
    # TEMPORARY - $version.ACCEPTS() needs work
    sub CLEAN-VER($version is copy) {
        # v1.0 -> 1.0
        $version.subst-mutate(/^[v || V] '.'?/, '', :x(1));

        # 0.100.1 -> 0.10.0.1
        if $version ~~ /(0 ** 2..*)/ {
            $version.subst-mutate(/(0 ** 2..*)/, $/[0].Str.comb.join('.'), :g);
        }

        # 0.02 -> 0.0.2
        if $version ~~ /(0\d+)/ {
            $version.subst-mutate(/(0\d+)/, $/[0].Str.comb.join('.'), :g);
        }

        return $version;
    }

    my $want-ver = Version.new: CLEAN-VER($v2);
    my $ver      = Version.new: $v1.Str;

    return Order::Same  if $ver eq $want-ver.Str;
    return Order::Less if $ver eq '*';

    # Version objects ACCEPTS do not seem to give a valid `cmp` result 
    # so this chops up version string in such a way that it ACCEPTS 
    # works as expected.
    if $ver.Str.chars > ($want-ver.Str.chars - ($want-ver.plus ?? 1 !! 0)) {
        my $leftovers = $ver.Str.substr($want-ver.Str.chars - 1).subst(/[\d || \w]/, '*', :g);
        $want-ver = Version.new: CLEAN-VER($want-ver.Str.substr(0, ($want-ver.plus ?? ($want-ver.Str.chars - 1) !! $want-ver.Str.chars)) ~ $leftovers ~ ($want-ver.plus ?? '+' !! ''));
        $want-ver = Version.new( CLEAN-VER($want-ver.Str.subst(/\.'*'/, '.0', :g)) ) unless $want-ver.plus;
    }
    elsif $ver.Str.chars < ($want-ver.Str.chars - ($want-ver.plus ?? 1 !! 0)) {
        my $leftovers = $want-ver.Str.substr($ver.Str.chars - 1, *-1).subst(/[\d || \w]/, $want-ver.plus ?? '*' !! 0);
        $ver = Version.new: CLEAN-VER($ver.Str ~ $leftovers);
    }

    return $ver cmp $want-ver;
}