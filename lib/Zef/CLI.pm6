unit module Zef::CLI;
# STDMuxer
#
# redirect all sub-processes stdout/stderr to current stdout with the format:
# `file-name.t \s* # <output>` such that we can just print everything as it comes 
# and still make a little sense of it (and allow it to be sorted)

# todo: handle line wrapping with seperator

# note: this still needs to be redone post-glr for --async to work properly, but i'm unsure why yet
sub procs2stdout(*@processes, :$max-width) is export {
    return unless @processes;
    my @basenames = gather for @processes -> $group {
        for $group.cache -> $item {
            for $item.cache { take $_.id.IO.basename }
        }
    }
    my $longest-basename = @basenames.max(*.chars);
    for @processes -> @group {
        for @group -> $proc {
            for $proc.stdout, $proc.stderr -> $stdio {
                $stdio.act: -> $out {
                    for $out.lines.cache.grep(*.chars) -> $line {
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


# Status/Message bar
sub CLI-WAITING-BAR(&code, str $message, Bool :$boring) is export {
    sub show-await(str $message, $promise) {
        # This works *much* better when using "\r" instead of some number of "\b"
        # Unfortunately MoarVM on Windows has a bug where it prints "\r" as if it were "\n"
        # (JVM is OK on windows, JVM/Moar are ok on linux)

        my $loading = Supply.interval(1);
        my $out = $*OUT;
        my $err = $*ERR;
        my $in  = $*IN;
        my int $last-line-len = 0;

        $*ERR = $*OUT = class :: {
            my $lock = Lock.new;
            my str ($e, $d);
            my int ($m, $n);

            $loading.act: {
                $e = do given ++$m { 
                    when 2  { '-==' }
                    when 3  { '=-=' }
                    when 4  { '==-' }
                    default { $m = 1; '===' }
                }
                $d = do given ++$n { 
                    when 2  { '.  ' }
                    when 3  { '.. ' }
                    when 4  { '...' }
                    when 5  { '.. ' }
                    when 6  { '.  ' }
                    default { $n = 1; '   ' }
                }

                print r-print;
            },
            done    => { print r-print; },
            closing => { print r-print; };

            method print(*@_) {
                if @_ {
                    my str $lines = @_.join;
                    $lock.protect({
                        my $out2 = $*OUT;
                        $*ERR = $*OUT = $out;
                        if $lines.chars {
                            my $line = r-print($lines.trim-trailing, :$last-line-len) ~ "\n";
                            print $line;
                            $last-line-len = 0;
                        }
                        my str $msg = "$e> $message$d";
                        my $status-bar := r-print($msg, :$last-line-len);
                        print $status-bar;
                        $last-line-len = $msg.chars;
                        $*ERR = $*OUT = $out2;
                    });
                }
            }

            method flush {}
        }

        $promise.result; # osx bug RT125758
        await $promise;
        $loading.done;
        $loading.close;
        $*ERR = $err;
        $*OUT = $out;

        print r-print("===> $message [done]\n", :$last-line-len);
        $promise;
    }

    sub fake-carriage(int $len) { my str $str = ("\b" x $len) || ''; ~$str }
    sub clear-line(int $len)    { my str $str = (" "  x $len) || ''; ~$str }
    sub r-print(str $str = '', int :$last-line-len = 0) {
        return $str unless $last-line-len;

        my $fc  := fake-carriage($last-line-len);
        my $cl  := clear-line($last-line-len);
        return "$fc$cl$fc$str";
    }
    say "===> $message" and return code() if $boring;
    my $promise = Promise.new;
    my $vow     = $promise.vow;
    my $await   = start { show-await($message, $promise) };

    my $retval = code();

    $vow.keep(True);
    $await.result; # osx bug RT125758
    await $await;

    $retval;
}