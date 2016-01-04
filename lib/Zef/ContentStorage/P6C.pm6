use Zef;

# todo: need a `git` fetcher
# todo: but in the mean time need to change git url to target its .zip

class Zef::ContentStorage::P6C does ContentStorage {
    has $.mirrors;
    has $.auto-update;
    has $.fetcher is rw;
    has $.cache is rw;

    method IO { $ = $!cache.IO.child('p6c').IO }
    method package-list-file { $ = self.IO.child('packages.json').IO }
    method !slurp-package-list { @ = |from-json(self.package-list-file.slurp) }

    method update {
        die "Failed to update p6c" unless $!mirrors.first({ $!fetcher.fetch($_, self.package-list-file) });
    }

    method index { $ = $!cache.IO.child("p6c.json").IO }

    method search(:$max-results = 5, *@identities, *%fields) {
        self.update if $.auto-update || !self.package-list-file.e;
        state @cache = self!slurp-package-list;
        return () unless @identities || %fields;
        temp %fields<name> .= append($_) for @identities;

        my $matches = gather PACKAGES: for @cache -> $package is copy {
            state $found-count;
            # %META is used like a mutable copy of $package so we can still return the orignal $package values
            my %META = $package.grep({.value ~~ Str|Int|Num|Rat|Array|List}).map: {.key.lc => .value>>.lc}
            my $ver  = NORMALZIE-VERSION( ~(%META<ver> // %META<version> // '*') );
            my $ok   = 0;

            FIELDS:
            for %fields.kv -> $field-orig, $filters {
                my $field = $field-orig.lc;
                next FIELDS unless %META{$field}:exists && %META{$field}.so;

                FILTERS:
                for $filters.grep(*.so).grep(* ~~ Str|Int|Num|Rat) -> $f {
                    temp $ver;

                    if $field ~~ /^ver[sion]?/ {
                        next PACKAGES unless $f;
                        my $want-ver = NORMALZIE-VERSION($f);
                        next PACKAGES if $ver.Str eq '*' && $want-ver.Str ne '*';

                        # Version objects ACCEPTS do not seem to give a valid `cmp` result 
                        # so this chops up version string in such a way that it ACCEPTS 
                        # works as expected.
                        if $want-ver.Str eq '*' {
                            # Take anything
                        }
                        elsif $ver.Str.chars > ($want-ver.Str.chars - ($want-ver.plus ?? 1 !! 0)) {
                            my $leftovers = $ver.Str.substr($want-ver.Str.chars - 1).subst(/[\d || \w]/, '*', :g);
                            $want-ver = NORMALZIE-VERSION($want-ver.Str.substr(0, ($want-ver.plus ?? ($want-ver.Str.chars - 1) !! $want-ver.Str.chars)) ~ $leftovers ~ ($want-ver.plus ?? '+' !! ''));
                            $want-ver = NORMALZIE-VERSION($want-ver.Str.subst(/\.'*'/, '.0', :g)) unless $want-ver.plus;
                        }
                        elsif $ver.Str.chars < ($want-ver.Str.chars - ($want-ver.plus ?? 1 !! 0)) {
                            my $leftovers = $want-ver.Str.substr($ver.Str.chars - 1, *-1).subst(/[\d || \w]/, $want-ver.plus ?? '*' !! 0);
                            $ver = NORMALZIE-VERSION($ver.Str ~ $leftovers);
                        }

                        next PACKAGES unless $want-ver.ACCEPTS($ver);
                        $ok++;
                    }
                    else {
                        next PACKAGES unless %META{$field}.so;

                        if $f ~~ /'*'/ {
                            my ($sub-search, $) = $f.lc.split('*', 2);
                            my $matches = any(%META{$field}.values>>.starts-with($sub-search));
                            $ok++ if $matches;
                        }
                        else {
                            my $matches = any(%META{$field}.values) cmp $f.lc;
                            $ok++ if any($matches) == Order::Same;
                        }
                    }
                }
            }

            if $ok == %fields.keys.elems {
                take $package;
                last PACKAGES if ++$found-count >= $max-results;
            }
        }

        return $matches;
    }

    sub NORMALZIE-VERSION($version is copy) {
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

        $ = Version.new($version)
    }
}
