unit module Zef::Utils::SystemInfo;

# the extra signal stuff is because JVM does not have a `signal` symbol
our sub signal-ignore($) { Supply.new }
our $signal-handler := &::("signal") ~~ Failure ?? &::("signal-ignore") !! &::("signal");
our $sig-resize     := ::("Signal::SIGWINCH");
try $signal-handler.($sig-resize).act: { $ = GET-TERM-COLUMNS() }

# Get terminal width
sub GET-TERM-COLUMNS is export {
    state $default-only;
    return $default-only if $default-only;

    if $*DISTRO.is-win {
        # Windowsy
        my $default = 80 - 1;
        try {
            my $proc   = shell("mode", :out, :!err, :enc('latin-1'));
            my $output = $proc.slurp(:close) if $ = $proc.so;
            return $default unless $output;

            if $output ~~ /'CON:' \n <.ws> '-'+ \n .*? \n \N+? $<cols>=[<.digit>+]/ {
                my $cols = $/<cols>.comb(/\d/).join;
                my $got_cols = (+$cols - 1) if $cols.chars;
                return ($default-only = ($got_cols ?? max($default, $got_cols) !! $default));
            }
        }
        return $default;
    }
    else {
        # Linuxy
        my $default = 120 - 1;

        try {
            my $proc = run('tput', 'cols', :out, :!err, :enc('latin-1'));
            my $cols = $proc.out.slurp(:close).lines.head if $ = $proc.so;
            my $got_cols = (+$cols - 1) if $cols.chars;
            return ($default-only = ($got_cols ?? max($default, $got_cols) !! $default));
        }

        return $default;
    }
}
