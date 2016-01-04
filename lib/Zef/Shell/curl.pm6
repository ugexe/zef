use Zef;
use Zef::Shell;

class Zef::Shell::curl is Zef::Shell does Fetcher does Probeable {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        # todo: check without spawning process (slow)
        state $curl-help = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }

            my $proc = zrun('curl', '--help', :out);
            my $nl   = Buf.new(10).decode;
            my @out <== grep *.so <== split $nl, $proc.out.slurp-rest;
            $proc.out.close;
            $ = $proc.exitcode == 0 ?? @out !! False;
        }

        so $curl-help;
    }

    method fetch($url, $save-as) {
        mkdir($save-as.IO.dirname) unless $save-as.IO.dirname.IO.e;
        my $proc = $.zrun('curl', '--silet', '-o', $save-as, $url);
        $ = ?$proc ?? $save-as !! False;
    }
}
