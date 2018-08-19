use Zef;

class Zef::Report does Pluggable does Reporter {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    method report($dist, Supplier :$logger) {
        my $reporters := self.plugins.grep(*.so).cache;

        my @reports = $reporters.map: -> $reporter {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => REPORT, phase => START, message => "Reporting with plugin: {$reporter.^name}" });
                $reporter.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => REPORT, phase => LIVE, message => $out }) }
                $reporter.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => REPORT, phase => LIVE, message => $err }) }
            }

            my $report = try $reporter.report($dist);

            $reporter.stdout.done;
            $reporter.stderr.done;

            $report;
        }

        return @reports.grep(*.defined);
    }
}
