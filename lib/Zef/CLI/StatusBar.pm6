unit module Zef::CLI::StatusBar;

sub CLI-WAITING-BAR(&code, str $message, Bool :$boring) is export {
    say "===> $message" and return code() if $boring;
    my $promise = Promise.new;
    my $vow     = $promise.vow;
    my $await   = start { show-await($message, $promise) };

    my $retval = code();

    $vow.keep(1);
    await $await;

    $retval;
}

# This works *much* better when using "\r" instead of some number of "\b"
# Unfortunately MoarVM on Windows has a bug where it prints "\r" as if it were "\n"
# (JVM is OK on windows, JVM/Moar are ok on linux)
sub show-await(str $message, *@promises) {
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


    await Promise.allof: @promises;
    $loading.done;
    $loading.close;
    $*ERR = $err;
    $*OUT = $out;

    print r-print("===> $message [done]\n", :$last-line-len);
    @promises;
}

sub fake-carriage(int $len) { my str $str = ("\b" x $len) || ''; ~$str }
sub clear-line(int $len)    { my str $str = (" "  x $len) || ''; ~$str }
sub r-print(str $str = '', int :$last-line-len = 0) {
    return $str unless $last-line-len;

    my $fc  := fake-carriage($last-line-len);
    my $cl  := clear-line($last-line-len);
    return "$fc$cl$fc$str";
}