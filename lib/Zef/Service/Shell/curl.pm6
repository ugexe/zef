use Zef;

class Zef::Service::Shell::curl does Fetcher does Probeable does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        state $probe = try { run('curl', '--help', :out, :err).exitcode == 0 ?? True !! False };
        ?$probe;
    }

    method fetch($url, $save-as) {
        my $cwd = $save-as.IO.parent andthen { .mkdir unless .e };
        my $proc = run('curl', '--silent', '-L', '-o', $save-as, $url, :$cwd, :out, :err);
        $proc.exitcode == 0 ?? $save-as !! False;
    }
}
