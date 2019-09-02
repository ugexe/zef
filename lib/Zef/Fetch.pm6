use Zef;
use Zef::Utils::FileSystem;
use Zef::Utils::URI;

class Zef::Fetch does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    method fetch-matcher($uri) { self.plugins.grep(*.fetch-matcher($uri)) }

    method fetch($uri, $save-to, Supplier :$logger, Int :$timeout) {
        my $fetchers := self.fetch-matcher($uri).cache;

        unless +$fetchers {
            my @report_enabled  = self.plugins.map(*.short-name);
            my @report_disabled = self.backends.map(*.<short-name>).grep({ $_ ~~ none(@report_enabled) });

            die "Enabled fetching backends [{@report_enabled}] don't understand $uri\n"
            ~   "You may need to configure one of the following backends, or install its underlying software - [{@report_disabled}]";
        }

        my $got := $fetchers.map: -> $fetcher {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => FETCH, phase => START, message => "Fetching $uri with plugin: {$fetcher.^name}" });
                $fetcher.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => FETCH, phase => LIVE, message => $out }) }
                $fetcher.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => FETCH, phase => LIVE, message => $err }) }
            }

            my $ret = lock-file-protect("{$save-to}.lock", -> {
                my $todo    = start { try $fetcher.fetch($uri, $save-to) };
                my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
                await Promise.anyof: $todo, $time-up;
                $logger.emit({ level => DEBUG, stage => FETCH, phase => LIVE, message => "Fetching $uri timed out" })
                    if $time-up.so && $todo.not;
                $todo.so ?? $todo.result !! Nil;
            });

            $fetcher.stdout.done;
            $fetcher.stderr.done;

            $ret;
        }

        return $got.first(*.so);
    }
}
