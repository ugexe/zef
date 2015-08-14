unit module Zef::Utils::SystemInfo;

our $MAX-TERM-COLS is export = GET-TERM-COLUMNS();
my sub signal-faker($) { Supply.new }
sub signal-handler(Signal $sig) {
    state $signal-wrapper = &::("signal") ~~ Failure ?? &::("signal-faker") !! &::("signal");
    state $signal-supply  = try { $signal-wrapper.($sig) } || signal-faker($sig);
}
&signal-handler(Signal::SIGINT).act: { $MAX-TERM-COLS = GET-TERM-COLUMNS(); say $MAX-TERM-COLS; }



# Get terminal width
sub GET-TERM-COLUMNS is export {
    if $*DISTRO.is-win {
        # Windowsy
        my $default = 80 - 1;
        my $r    = shell("mode", :out);
        my $line = $r.out.lines.join("\n");
        return $default unless $line;

        if $line ~~ /'CON:' \n <.ws> '-'+ \n .*? \n \N+? $<cols>=[<.digit>+]/ {
            my $cols = $/<cols>.comb(/\d/).join;
            return +$cols - 1 if try { +$cols }
        }
        return $default;
    }
    else {
        # Linuxy
        my $default = 120 - 1;
        my $tput    = run("tput", "cols", :out);
        if $tput.out.get ~~ /$<cols>=<.digit>+/ {
            my $cols = ~$/<cols>.comb(/\d/).join;
            return +$cols - 1 if try { +$cols }

        }
        return $default;
    }
}
