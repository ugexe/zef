use Zef;
use Zef::Utils::FileSystem;

# A 'Fetcher' that uses 1 or more other 'Fetcher' instances as backends. It abstracts the logic
# to do 'grab this uri with the first backend that supports the given uri'.

class Zef::Fetch does Fetcher does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    # Returns true if any of the backends 'fetch-matcher' understand the given uri/path
    method fetch-matcher($uri --> Bool:D) { return so self!fetch-matcher($uri) }

    # Returns the backends that understand the given uri based on their fetch-matcher result
    method !fetch-matcher($uri --> Array[Fetcher]) {
        my @matching-backends = self.plugins.grep(*.fetch-matcher($uri));

        my Fetcher @results = @matching-backends;
        return @results;
    }

    # Fetch the given url
    # Will return the first successful result while attempting to fetch the given $candi
    # Note this differs from other 'Fetch' adapters .fetch() which take a $uri as the first
    # parameter, not a $candi... thats so the logging mechanism can emit it, so ideally
    # we would just pass in the $uri separate; otherwise can just do Candidate.new(:uri($url))
    # to fetch something that isn't a raku distribution/candidate/module (such as p6c.json)
    method fetch(Candidate $candi, IO() $save-to, Supplier :$logger, Int :$timeout --> IO::Path) {
        my $uri      = $candi.uri;
        my @fetchers = self!fetch-matcher($uri).cache;

        unless +@fetchers {
            my @report_enabled  = self.plugins.map(*.short-name);
            my @report_disabled = self.backends.map(*.<short-name>).grep({ $_ ~~ none(@report_enabled) });

            die "Enabled fetching backends [{@report_enabled}] don't understand $uri\n"
            ~   "You may need to configure one of the following backends, or install its underlying software - [{@report_disabled}]";
        }

        my $got := @fetchers.map: -> $fetcher {
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

        my IO::Path $result = $got.grep(*.so).map(*.IO).head;
        return $result;
    }
}

