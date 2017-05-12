use Zef;

class Zef::Report does Pluggable does Reporter {
    method report($dist, Supplier :$logger) {
        my $reporters := self.plugins.grep(*.so).cache;

        my @report_enabled  = self.plugins.map(*.short-name);
        my @report_disabled = self.backends.map(*.<short-name>).grep({ $_ ~~ none(@report_enabled) });

        my $got = first *.defined, gather for $reporters -> $reporter {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => REPORT, phase => START, payload => self, message => "Reporting with plugin: {$reporter.^name}" });
                $reporter.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => REPORT, phase => LIVE, message => $out }) }
                $reporter.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => REPORT, phase => LIVE, message => $err }) }
            }

            my $out = $reporter.report($dist);

            $reporter.stdout.done;
            $reporter.stderr.done;
            take $out;
        }

        $got;
    }
}
