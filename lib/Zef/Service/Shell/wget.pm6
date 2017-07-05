use Zef;
use Zef::Shell;

class Zef::Service::Shell::wget is Zef::Shell does Fetcher does Probeable does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        state $wget-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            so zrun('wget', '--help', :!out, :!err);
        }
        ?$wget-probe;
    }

    method fetch($url, $save-as) {
        mkdir($save-as.IO.parent) unless $save-as.IO.parent.IO.e;
        my $proc = $.zrun('wget', '--quiet', $url, '-O', $save-as, :!out, :!err);
        $ = ?$proc ?? $save-as !! False;
    }
}
