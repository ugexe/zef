use Zef;
use Zef::Utils::URI;

class Zef::Fetch does Pluggable {
    method ACCEPTS($uri) { $ = $uri ~~ @$.plugins }

    method fetch($uri, $save-as, Supplier :$stdout, Supplier :$stderr) {
        my $fetcher = self.plugins.first(*.fetch-matcher($uri));

        die "No fetching backend available" unless ?$fetcher;

        $fetcher.stdout.Supply.act: -> $out { ?$stdout ?? $stdout.emit($out) !! $*OUT.say($out) }
        $fetcher.stderr.Supply.act: -> $err { ?$stderr ?? $stderr.emit($err) !! $*ERR.say($err) }

        my $got = $fetcher.fetch($uri, $save-as);

        $fetcher.stdout.done;
        $fetcher.stderr.done;

        return $got;
    }
}
