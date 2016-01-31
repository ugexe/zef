use Zef;
use Zef::Shell;

class Zef::Shell::curl is Zef::Shell does Fetcher does Probeable does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        state $curl-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }

            my $proc = zrun('curl', '--help', :out);
            my $nl   = Buf.new(10).decode;
            my $out  = |$proc.out.lines;
            $proc.out.close;
            $ = ?$proc;
        }
        ?$curl-probe;
    }

    method fetch($url, $save-as) {
        mkdir($save-as.IO.dirname) unless $save-as.IO.dirname.IO.e;
        my $proc = $.zrun('curl', '--silent', '-o', $save-as, $url);
        $ = ?$proc ?? $save-as !! False;
    }
}
