unit module Zef::CLI::STDMux;

# redirect all sub-processes stdout/stderr to current stdout with the format:
# `file-name.t \s* # <output>` such that we can just print everything as it comes 
# and still make a little sense of it (and allow it to be sorted)

# todo: handle line wrapping with seperator
sub procs2stdout(*@processes) is export {
    return unless @processes;
    my @basenames = @processes>>.id>>.IO>>.basename;
    my $longest-basename = @basenames.reduce({ $^a.chars > $^b.chars ?? $^a !! $^b });
    for @processes -> $proc {
        for $proc.stdout, $proc.stderr -> $stdio {
            $stdio.tap: -> $out { 
                for $out.lines.grep(*.so) -> $line {
                    state $to-print ~= sprintf(
                        "%-{$longest-basename.chars + 1}s# %s\n",
                        $proc.id.IO.basename, 
                        $line 
                    );
                    LAST { print $to-print if $to-print }
                }
            }
        }
    }
}