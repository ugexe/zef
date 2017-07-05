unit module Zef::Utils::SystemInfo;

# the extra signal stuff is because JVM does not have a `signal` symbol
our sub signal-ignore($) { Supply.new }
our $signal-handler := &::("signal") ~~ Failure ?? &::("signal-ignore") !! &::("signal");
our $sig-resize     := ::("Signal::SIGWINCH");
try $signal-handler.($sig-resize).act: { $ = GET-TERM-COLUMNS() }

# Get terminal width
sub GET-TERM-COLUMNS is export {
    if $*DISTRO.is-win {
        # Windowsy
        my $default = 80 - 1;
        my $r    = shell("mode", :out, :!err, :enc('latin-1'));
        my $line = $r.out.lines.join("\n");
        $r.out.close;
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
        my $tput    = run("tput", "cols", :out, :!err :enc('latin-1'));
        my @lines   = $tput.out.lines;
        $tput.out.close;
        if @lines[0] ~~ /$<cols>=<.digit>+/ {
            my $cols = ~$/<cols>.comb(/\d/).join;
            return +$cols - 1 if try { +$cols }
        }
        return $default;
    }
}
