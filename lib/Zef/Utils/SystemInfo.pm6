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
        try {
            my $line = shell("mode", :out, :!err, :enc('latin-1')).slurp(:close);
            return $default unless $line;

            if $line ~~ /'CON:' \n <.ws> '-'+ \n .*? \n \N+? $<cols>=[<.digit>+]/ {
                my $cols = $/<cols>.comb(/\d/).join;
                return +$cols - 1 if try { +$cols }
            }
        }
        return $default;
    }
    else {
        # Linuxy
        my $default = 120 - 1;
        try {
            my $output = shell('echo $COLUMNS', :merge, :enc('latin-1')).out.slurp(:close).chomp.Int;
            return $output;
        }
        return $default;
    }
}
