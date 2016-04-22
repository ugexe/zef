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
            so zrun('curl', '--help');
        }
        ?$curl-probe;
    }

    method fetch($url, $save-as) {
        mkdir($save-as.IO.parent) unless $save-as.IO.parent.IO.e;
        my $proc = $.zrun('curl', '--silent', '-o', $save-as, $url);
        $ = ?$proc ?? $save-as !! False;
    }
}
