use Zef;
use Zef::Utils::URI;

class Zef::Fetch does Pluggable {
    method fetch($uri, $save-as, Supplier :$logger) {
        my $fetchers := self.plugins.grep(*.fetch-matcher($uri)).cache;
        die "No fetching backend available" unless $fetchers.head(1);

        my $got := $fetchers.map: -> $fetcher {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => FETCH, phase => START, payload => self, message => "Fetching with plugin: {$fetcher.^name}" });
                $fetcher.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => FETCH, phase => LIVE, message => $out }) }
                $fetcher.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => FETCH, phase => LIVE, message => $err }) }
            }

            my $ret = try $fetcher.fetch($uri, $save-as);

            $fetcher.stdout.done;
            $fetcher.stderr.done;

            $ret;
        }

        return $got.first(*.so);
    }
}
