use Zef;
use Zef::Shell;

class Zef::Shell::wget is Zef::Shell does Fetcher does Probeable does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        state $wget-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            so zrun('wget', '--help');
        }
        ?$wget-probe;
    }

    method fetch($url, $save-as) {
        mkdir($save-as.IO.dirname) unless $save-as.IO.dirname.IO.e;
        my $proc = $.zrun('wget', '--quiet', $url, '-O', $save-as);
        $ = ?$proc ?? $save-as !! False;
    }
}
