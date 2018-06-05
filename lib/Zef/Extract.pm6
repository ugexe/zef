use Zef;
use Zef::Utils::FileSystem;

class Zef::Extract does Pluggable {
    method extract($path, $extract-to, Supplier :$logger, Int :$timeout) {
        die "Can't extract non-existent path: {$path}" unless $path.IO.e;
        die "Can't extract to non-existent path: {$extract-to}" unless $extract-to.IO.e || $extract-to.IO.mkdir;

        my $extractors = self!extractors($path).map(-> $extractor {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => EXTRACT, phase => START, message => "Extracting with plugin: {$extractor.^name}" });
                $extractor.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => EXTRACT, phase => LIVE, message => $out }) }
                $extractor.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => EXTRACT, phase => LIVE, message => $err }) }
            }

            my $out = lock-file-protect("{$extract-to}.lock", -> {
                my $todo    = start { try $extractor.extract($path, $extract-to) };
                my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
                await Promise.anyof: $todo, $time-up;
                $logger.emit({ level => DEBUG, stage => FETCH, phase => LIVE, message => "Testing $path timed out" })
                    if $time-up.so && $todo.not;
                $todo.so ?? $todo.result !! Nil
            });

            $extractor.stdout.done;
            $extractor.stderr.done;

            # really just saving $extractor for an error message later on. should do away with it later
            $extractor => $out;
        });

        # gnu tar on windows doesn't always work as I expect, so try another plugin if extraction fails
        my $extracted-to = $extractors.grep({
            $logger.emit({ level => WARN, stage => EXTRACT, phase => LIVE, message => "Extracting with plugin {.key.^name} aborted." })
                if ?$logger && !(.value.defined && .value.IO.e);
            .value.defined && .value.IO.e;
        }).map(*.value).head;
        die "something went wrong extracting {$path} to {$extract-to} with {$.plugins.join(',')}" unless $extracted-to.IO.e;

        return $extracted-to.IO;
    }

    method ls-files($path, :$logger) {
        my $extractors := self!extractors($path);
        my $name-paths := $extractors.map(*.ls-files($path)).first(*.so).map(*.IO);
        $name-paths.map({ .is-absolute ?? $path.child(.relative($path)).cleanup.relative($path) !! $_ });
    }

    method !extractors($path) {
        my $extractors := self.plugins.grep(*.extract-matcher($path)).cache;

        unless +$extractors {
            my @report_enabled  = self.plugins.map(*.short-name);
            my @report_disabled = self.backends.map(*.<short-name>).grep({ $_ ~~ none(@report_enabled) });

            die "Enabled extracting backends [{@report_enabled}] don't understand $path\n"
            ~   "You may need to configure one of the following backends, or install its underlying software - [{@report_disabled}]";
        }

        $extractors;
    }
}
