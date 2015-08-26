use v6;
END { exit 0 }
LEAVE { say "\n[HOOK: {$*PROGRAM.basename}] launched OK"; }

my $bugfix-wrapper = '#!/usr/bin/env perl6
sub MAIN(:$name, :$auth, :$ver, *@, *%) {
    shift @*ARGS if $name;
    shift @*ARGS if $auth;
    shift @*ARGS if $ver;
    my @installations = flat @*INC.grep( { .starts-with("inst#") } )\
        .map: { CompUnitRepo::Local::Installation.new(PARSE-INCLUDE-SPEC($_).[*-1]) };
    my @binaries = flat @installations.map: {.files("bin/zef", :$name, :$auth, :$ver)}
    unless +@binaries {
        @binaries = flat @installations.map: {.files("bin/zef")}
        if +@binaries {
            note q:to/SORRY/;
                ===SORRY!===
                No candidate found for "zef" that match your criteria.
                Did you perhaps mean one of these?
                SORRY
            my %caps = :name(["Distribution", 12]), :auth(["Author(ity)", 11]), :ver(["Version", 7]);
            for @binaries -> $dist {
                for %caps.kv -> $caption, @opts is rw {
                    @opts[1] = max @opts[1], ($dist{$caption} // "").Str.chars
                }
            }
            note "  " ~ %caps.values.map({ sprintf("%-*s", .[1], .[0]) }).join(" | ");
            for @binaries -> $dist {
                note "  " ~ %caps.kv.map( -> $k, $v { sprintf("%-*s", $v.[1], $dist{$k} // "") } ).join(" | ")
            }
        }
        else {
            note "===SORRY!===\nNo candidate found for \"zef\".\n";
        }
        exit 1;
    }

    exit run($*EXECUTABLE-NAME, @binaries[0]<files><bin/zef>, @*ARGS).exitcode
}
';



my @curlis = [CompUnitRepo::Local::Installation.new(%*CUSTOM_LIB<site>),];
for @curlis -> $cur {
    my $bin-path = $cur.IO.child('bin/zef');
    next unless $bin-path.IO.e;
    $bin-path.IO.spurt: $bugfix-wrapper;
    say "\n[HOOK: {$*PROGRAM.basename}] MANIFEST file-id fix applied.";
}

exit 0;