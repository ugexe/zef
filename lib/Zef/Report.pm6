use Zef;

class Zef::Report does Pluggable does Reporter {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    method report($candi, Supplier :$logger) {
        my $reporters := self.plugins.grep(*.so).cache;

        my @reports = $reporters.map: -> $reporter {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => REPORT, phase => START, candi => $candi, message => "Reporting with plugin: {$reporter.^name}" });
                $reporter.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => REPORT, phase => LIVE, candi => $candi, message => $out }) }
                $reporter.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => REPORT, phase => LIVE, candi => $candi, message => $err }) }
            }

            my $report = try $reporter.report($candi.dist);

            $report;
        }

        return @reports.grep(*.defined);
    }
}
