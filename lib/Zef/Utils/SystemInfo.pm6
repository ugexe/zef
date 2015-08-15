unit module Zef::Utils::SystemInfo;

our $MAX-TERM-COLS is export = GET-TERM-COLUMNS();
our sub signal-ignore($) { Supply.new }
our $signal-handler := &::("signal") ~~ Failure ?? &::("signal-ignore") !! &::("signal");
our $sig-resize     := ::("Signal::SIGWINCH");
$signal-handler.($sig-resize).act: { $MAX-TERM-COLS = GET-TERM-COLUMNS() }



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
