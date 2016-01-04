use Zef;
use Zef::Shell;

class Zef::Shell::wget is Zef::Shell does Fetcher does Probeable {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        # todo: check without spawning process (slow)
        state $wget-help = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }

            my $proc = zrun('wget', '--help', :out);
            my $nl   = Buf.new(10).decode;
            my @out <== grep *.so <== split $nl, $proc.out.slurp-rest;
            $proc.out.close;
            $ = $proc.exitcode == 0 ?? @out !! False;
        }

        so $wget-help;
    }

    method fetch($url, $save-as) {
        mkdir($save-as.IO.dirname) unless $save-as.IO.dirname.IO.e;
        my $proc = $.zrun('wget', '--quiet', $url, '-O', $save-as);
        $ = ?$proc ?? $save-as !! False;
    }
}
