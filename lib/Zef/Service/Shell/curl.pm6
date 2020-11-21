use Zef;

# A simple 'Fetcher' that uses the `curl` command to fetch uris

class Zef::Service::Shell::curl does Fetcher does Probeable does Messenger {
    # Return true if this Fetcher understands the given uri/path
    method fetch-matcher($url --> Bool:D) {
        return so <https http>.first({ $url.lc.starts-with($_) });
    }

    # Return true if the `curl` command is available to use
    method probe(--> Bool:D) {
        state $probe = try { zrun('curl', '--help', :!out, :!err).so };
    }

    # Fetch the given url
    method fetch($url, IO() $save-as --> IO::Path) {
        die "target download directory {$save-as.parent} does not exist and could not be created"
            unless $save-as.parent.d || mkdir($save-as.parent);

        my $passed;
        react {
            my $cwd := $save-as.parent;
            my $ENV := %*ENV;
            my $proc = zrun-async('curl', '--silent', '-L', '-z', $save-as.absolute, '-o', $save-as.absolute, $url);
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return ($passed && $save-as.e) ?? $save-as !! Nil;
    }
}
