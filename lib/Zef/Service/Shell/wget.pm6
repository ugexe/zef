use Zef;

class Zef::Service::Shell::wget does Fetcher does Probeable does Messenger {
    method fetch-matcher($url) { $ = $url.lc.starts-with('http://' | 'https://') }

    method probe {
        state $probe = try { zrun('wget', '--help', :!out, :!err).so };
    }

    method fetch($url, IO() $save-as) {
        die "target download directory {$save-as.parent} does not exist and could not be created"
            unless $save-as.parent.d || mkdir($save-as.parent);

        my $passed;
        react {
            my $cwd := $save-as.parent;
            my $ENV := %*ENV;
            my $proc = zrun-async('wget', '-P', $cwd, '--quiet', $url, '-O', $save-as.absolute);
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        ($passed && $save-as.e) ?? $save-as !! False;
    }
}
