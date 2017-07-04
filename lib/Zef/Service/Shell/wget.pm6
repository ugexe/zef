use Zef;

class Zef::Service::Shell::wget does Fetcher does Probeable does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        state $probe = try { run('wget', '--help', :out, :err).exitcode == 0 ?? True !! False };
        ?$probe;
    }

    method fetch($url, $save-as) {
        my $cwd = $save-as.IO.parent andthen { .mkdir unless .e };
        my $proc = run('wget', '--quiet', $url, '-O', $save-as, :$cwd, :out, :err);
        $proc.exitcode == 0 ?? $save-as !! False;
    }
}
