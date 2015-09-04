unit module Zef::CLI::STDMux;

# redirect all sub-processes stdout/stderr to current stdout with the format:
# `file-name.t \s* # <output>` such that we can just print everything as it comes 
# and still make a little sense of it (and allow it to be sorted)

# todo: handle line wrapping with seperator

# note: this still needs to be redone post-glr for --async to work properly, but i'm unsure why yet
sub procs2stdout(*@processes, :$max-width) is export {
    return unless @processes;
    my @basenames = gather for @processes -> $group {
        for $group.list -> $item {
            for $item.list { take $_.id.IO.basename }
        }
    }
    my $longest-basename = @basenames.max(*.chars);
    for @processes -> @group {
        for @group -> $proc {
            for $proc.stdout, $proc.stderr -> $stdio {
                $stdio.act: -> $out {
                    for $out.lines.list.grep(*.chars) -> $line {
                        my $formatted = sprintf(
                            "%-{$longest-basename.chars + 1}s# %s",
                            $proc.id.IO.basename,
                            $line
                        );

                        print "{_widther($formatted, :$max-width)}\n";
                    }
                }
            }
        }
    }
}

sub _widther($str, :$max-width) is export {
    return $str unless ?$max-width && $str.chars > $max-width;
    my $cutoff = $str.substr(0, $max-width);
    return ($cutoff.substr(0,*-3) ~ '...') if $cutoff.substr(*-1,1) ~~ /\S/;
    return ($cutoff.substr(0,*-3) ~ '...') if $cutoff.substr(*-2,1) ~~ /\S/;
    return ($cutoff.substr(0,*-3) ~ '...') if $cutoff.substr(*-3,1) ~~ /\S/;
    return $cutoff;
}
