use Zef;
use Zef::Utils::FileSystem;
use Zef::Utils::URI;

class Zef::Fetch does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    method fetch-matcher($uri) { self.plugins.grep(*.fetch-matcher($uri)) }

    method fetch($candi, $save-to, Supplier :$logger, Int :$timeout) {
        my $uri      := $candi.uri;
        my $fetchers := self.fetch-matcher($uri).cache;

        unless +$fetchers {
            my @report_enabled  = self.plugins.map(*.short-name);
            my @report_disabled = self.backends.map(*.<short-name>).grep({ $_ ~~ none(@report_enabled) });

            die "Enabled fetching backends [{@report_enabled}] don't understand $uri\n"
            ~   "You may need to configure one of the following backends, or install its underlying software - [{@report_disabled}]";
        }

        my $got := $fetchers.map: -> $fetcher {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => FETCH, phase => START, candi => $candi, message => "Fetching $uri with plugin: {$fetcher.^name}" });
                $fetcher.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => FETCH, phase => LIVE, candi => $candi, message => $out }) }
                $fetcher.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => FETCH, phase => LIVE, candi => $candi, message => $err }) }
            }

            my $ret = lock-file-protect("{$save-to}.lock", -> {
                my $todo    = start { try $fetcher.fetch($uri, $save-to) };
                my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
                await Promise.anyof: $todo, $time-up;
                $logger.emit({ level => DEBUG, stage => FETCH, phase => LIVE, candi => $candi, message => "Fetching $uri timed out" })
                    if ?$logger && $time-up.so && $todo.not;
                $todo.so ?? $todo.result !! Nil;
            });

            $ret;
        }

        return $got.first(*.so);
    }
}

