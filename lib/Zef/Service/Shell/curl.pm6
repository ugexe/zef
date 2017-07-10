use Zef;

class Zef::Service::Shell::curl does Fetcher does Probeable does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        state $probe = try { run('curl', '--help', :!out, :!err).so };
    }

    method fetch($url, $save-as) {
        my $cwd = $save-as.IO.parent andthen { .mkdir unless .e };
        my $proc = run('curl', '--silent', '-L', '-z', $save-as, '-o', $save-as, $url, :!out :!err);
        $proc.so ?? $save-as !! False;
    }
}
