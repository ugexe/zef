use Zef;
use Zef::Utils::URI;

class Zef::Fetch does Pluggable {
    method fetch($uri, $save-as, Supplier :$logger) {
        my $fetcher = self.plugins.first(*.fetch-matcher($uri));

        die "No fetching backend available" unless ?$fetcher;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => FETCH, phase => START, payload => self, message => "Fetching with plugin: {$fetcher.^name}" });
            $fetcher.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => FETCH, phase => LIVE, message => $out }) }
            $fetcher.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => FETCH, phase => LIVE, message => $err }) }
        }

        my $got = $fetcher.fetch($uri, $save-as);

        $fetcher.stdout.done;
        $fetcher.stderr.done;

        return $got;
    }
}
