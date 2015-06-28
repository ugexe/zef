role Zef::Authority::Net { ... }



# Authorities can provide meta info on project and a target to send test reports
role Zef::Authority {
    has @.projects;

    method update-projects { ... }

    method search(*@names, *%fields) {
        return unless @names || %fields;
        temp %fields<name> .= push($_) for @names;

        # todo: turn this into a method `cmp` for Distribution objects
        my @matches = gather PROJECTS: for @!projects -> $project is copy {
            my $ver = Version.new: CLEAN-VER( ~($project.<ver> // $project.<version> // '*') );

            for $project.keys -> $k {
                $project{$k}:delete and next
                    unless $project{$k}.isa(Str) || $project{$k}.isa(Int) || $project{$k}.isa(Whatever);
                $project{$k.lc} = $project{$k}:delete;
            }

            FIELDS:
            for %fields.kv -> $field, $filters {
                FILTERS:
                for $filters.list -> $f {
                    next FILTERS unless $f;
                    next FILTERS unless $f.isa(Str) || $f.isa(Int) || $f.isa(Whatever);
                    next FILTERS unless $project{$field.lc}:exists;
                    temp $ver;

                    if $field.lc ~~ /^ver[sion]?/ {
                        next PROJECTS unless $f;
                        my $want-ver = Version.new: CLEAN-VER($f);
                        next PROJECTS if $ver.Str eq '*' && $want-ver.Str ne '*';

                        # Version objects ACCEPTS do not seem to give a valid `cmp` result 
                        # so this chops up version string in such a way that it ACCEPTS 
                        # works as expected.
                        if $ver.Str.chars > ($want-ver.Str.chars - ($want-ver.plus ?? 1 !! 0)) {
                            my $leftovers = $ver.Str.substr($want-ver.Str.chars - 1).subst(/[\d || \w]/, '*', :g);
                            $want-ver = Version.new: CLEAN-VER($want-ver.Str.subst(0, ($want-ver.plus ?? '*-1' !! '*')) ~ $leftovers ~ ($want-ver.plus ?? '+' !! ''));
                            $want-ver = Version.new( CLEAN-VER($want-ver.Str.subst(/\.'*'/, '.0', :g)) ) unless $want-ver.plus;
                        }
                        elsif $ver.Str.chars < ($want-ver.Str.chars - ($want-ver.plus ?? 1 !! 0)) {
                            my $leftovers = $want-ver.Str.substr($ver.Str.chars, *-1).subst(/[\d || \w]/, $want-ver.plus ?? '*' !! 0);
                            $ver = Version.new: CLEAN-VER($ver.Str ~ $leftovers);
                        }

                        next PROJECTS unless $want-ver.ACCEPTS($ver);
                    }
                    else {
                        next PROJECTS unless ($project.{$field.lc}.lc cmp $f.lc) == Order::Same;
                    }
                }
            }

            take $project;
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

