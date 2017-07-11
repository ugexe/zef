use Zef;

class Zef::Service::Shell::wget does Fetcher does Probeable does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        state $probe = try { zrun('wget', '--help', :!out, :!err).so };
    }

    method fetch($url, $save-as) {
        my $cwd = $save-as.IO.parent andthen { .mkdir unless .e };
        my $proc = zrun('wget', '-N', '-P', $cwd, '--quiet', $url, '-O', $save-as, :!out, :!err, :$cwd);
        $proc.so ?? $save-as !! False;
    }
}
