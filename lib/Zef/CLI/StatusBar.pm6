unit module Zef::CLI::StatusBar;

sub CLI-WAITING-BAR(&code, $status, Bool :$boring) is export {
    say "===> $status" and return code() if $boring;
    my $promise = Promise.new;
    my $vow     = $promise.vow;
    my $await   = start { show-await($status, $promise) };

    my $retval = code();

    $vow.keep(1);
    await $await;

    $retval;
}

# This works *much* better when using "\r" instead of some number of "\b"
# Unfortunately MoarVM on Windows has a bug where it prints "\r" as if it were "\n"
# (JVM is OK on windows, JVM/Moar are ok on linux)
sub show-await($message, *@promises) {
    my $loading = Supply.interval(1);
    my $out = $*OUT;
    my $err = $*ERR;
    my $in  = $*IN;
    my $last-line-len = 0;

    $*ERR = $*OUT = class :: {
        my $lock = Lock.new;
        my ($e, $m, $n, $d);

        $loading.tap(
        {
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

            print r-print('');
        },
            done    => { print r-print(''); },
            closing => { print r-print(''); },
        );

        method print(*@_) {
            if @_ {
                my $lines = @_.join;
                $lock.protect({
                    my $out2 = $*OUT;
                    $*ERR = $*OUT = $out;
                    if $lines.chars {
                        my $line = r-print($lines.trim-trailing, :$last-line-len);
                        $line ~= "\n";
                        print $line;
                        $last-line-len = 0;
                    }
                    my $msg = "$e> $message$d";
                    my $status-bar = r-print($msg, :$last-line-len);
                    print $status-bar;
                    $last-line-len = $msg.chars;
                    $*ERR = $*OUT = $out2;
                });
            }
        }

        method flush {}
    }


    await Promise.allof: @promises;
    $loading.close;
    $*ERR = $err;
    $*OUT = $out;
    print r-print("===> $message [done]\n", :$last-line-len);
}

sub fake-carriage($len) { my Str $str = ("\b" x $len) || ''; ~$str }
sub clear-line($len)    { my Str $str = (" "  x $len) || ''; ~$str }
sub r-print($str = '', :$last-line-len = 0) { 
    if $last-line-len {
        my $fc  = fake-carriage($last-line-len);
        my $cl  = clear-line($last-line-len);
        my $ret = "$fc$cl$fc$str";
    }
    else {
        return $str;
    }
}