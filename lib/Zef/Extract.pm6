use Zef;
use Zef::Utils::FileSystem;

class Zef::Extract does Pluggable {
    method extract($path, $extract-to, Supplier :$logger) {
        die "Can't extract non-existent path: {$path}" unless $path.IO.e;
        die "Can't extract to non-existent path: {$extract-to}" unless $extract-to.IO.e || $extract-to.IO.mkdir;
        my $extractors := self.plugins.grep(*.extract-matcher($path)).cache;
        die "No extracting backend available" unless ?$extractors;

        my $got = first *.IO.e, gather for $extractors -> $extractor {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => EXTRACT, phase => START, payload => self, message => "Extracting with plugin: {$extractor.^name}" });
                $extractor.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => EXTRACT, phase => LIVE, message => $out }) }
                $extractor.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => EXTRACT, phase => LIVE, message => $err }) }
            }

            my $out = lock-file-protect("{$extract-to}.lock", -> { try $extractor.extract($path, $extract-to) });

            $extractor.stdout.done;
            $extractor.stderr.done;
            take $out;
        }

        die "something went wrong extracting {$path} to {$extract-to} with {$.plugins.join(',')}" unless $got;
        return $got;
    }
}
