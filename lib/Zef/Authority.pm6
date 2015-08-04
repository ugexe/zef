role Zef::Authority::Net { ... }



# Authorities can provide meta info on project and a target to send test reports
role Zef::Authority {
    has @.projects is rw;

    submethod BUILD(:$projects-file) {
        if ?$projects-file {
            if ?$projects-file.IO.e {
                my $json     := from-json($projects-file.IO.slurp);
                @!projects    = try { $json.list }\
                    or fail "!!!> Invalid projects file.";
            }
            else {
                fail "!!!> Project file does not exist: {$projects-file}";
            }
        }
    }

    method update-projects { ... }

    method search(*@names, *%fields) {
        return () unless @names || %fields;
        temp %fields<name> .= push($_) for @names;

        # todo: turn this into a method `cmp` for Distribution objects.
        # Also probably need to create specialized rules for each field
        # so we can do things like version ranges in a dependency string.
        my @matches = gather PROJECTS: for @!projects -> $project is copy {
            my %META;
            for $project.kv -> $k, $v {
                if $v.defined && $v ~~ Str|Int|Num|Rat|Array|List {
                    %META{$k.lc} = $v>>.lc if $v.so;
                }
            }
            my $ver = Version.new: CLEAN-VER( ~(%META<ver> // %META<version> // '*') );
            my $ok  = 0;

            FIELDS:
            for %fields.kv -> $field-orig, $filters {
                my $field = $field-orig.lc;
                next FIELDS unless %META{$field}:exists && %META{$field}.so;
                FILTERS:

                for $filters.list -> $f {
                    next unless $f.so;
                    next FILTERS unless $f.isa(Str) || $f.isa(Int) || $f.isa(Num) || $f.isa(Rat);
                    temp $ver;

                    if $field ~~ /^ver[sion]?/ {
                        next PROJECTS unless $f;
                        my $want-ver = Version.new: CLEAN-VER($f);
                        next PROJECTS if $ver.Str eq '*' && $want-ver.Str ne '*';

                        # Version objects ACCEPTS do not seem to give a valid `cmp` result 
                        # so this chops up version string in such a way that it ACCEPTS 
                        # works as expected.
                        if $want-ver.Str eq '*' {
                            # Take anything
                        }
                        elsif $ver.Str.chars > ($want-ver.Str.chars - ($want-ver.plus ?? 1 !! 0)) {
                            my $leftovers = $ver.Str.substr($want-ver.Str.chars - 1).subst(/[\d || \w]/, '*', :g);
                            $want-ver = Version.new: CLEAN-VER($want-ver.Str.substr(0, ($want-ver.plus ?? ($want-ver.Str.chars - 1) !! $want-ver.Str.chars)) ~ $leftovers ~ ($want-ver.plus ?? '+' !! ''));
                            $want-ver = Version.new( CLEAN-VER($want-ver.Str.subst(/\.'*'/, '.0', :g)) ) unless $want-ver.plus;
                        }
                        elsif $ver.Str.chars < ($want-ver.Str.chars - ($want-ver.plus ?? 1 !! 0)) {
                            my $leftovers = $want-ver.Str.substr($ver.Str.chars - 1, *-1).subst(/[\d || \w]/, $want-ver.plus ?? '*' !! 0);
                            $ver = Version.new: CLEAN-VER($ver.Str ~ $leftovers);
                        }

                        next PROJECTS unless $want-ver.ACCEPTS($ver);
                        $ok++;
                    }
                    else {
                        next PROJECTS unless %META{$field}.so;

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

            take $project if $ok == %fields.keys.elems;
        }

        return @matches;
    }

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
}

