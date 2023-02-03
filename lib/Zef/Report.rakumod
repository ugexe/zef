use Zef;

class Zef::Report does Pluggable does Reporter {

    =begin pod

    =title class Zef::Report

    =subtitle A configurable implementation of the Reporter interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Report;
        use Zef::Distribution::Local;

        # Setup with a single installer backend
        my $reporter = Zef::Report.new(
            backends => [
                { module  => "Zef::Service::FileReporter" },
            ],
        );

        # Assuming our current directory is a raku distribution...
        my $dist-to-report  = Zef::Distribution::Local.new($*CWD);
        my $candidate       = Candidate.new(dist => $dist-to-report);
        my $logger          = Supplier.new andthen *.Supply.tap: -> $m { say $m.<message> }

        # ...report the distribution using the all available backends
        my $reported = so $reporter.report($candidate, :$logger);
        say $reported ?? 'Reported OK' !! 'Something went wrong...';

    =end code

    =head1 Description

    A C<Reporter> class that uses 1 or more other C<Reporter> instances as backends. It abstracts the logic
    to do 'report this distribution with every backend that supports the given distribution'.

    =head1 Methods

    =head2 method report

        method report(Candidate $candi, Supplier :$logger)

    Reports information about the distribution C<$candi.dist> to a temporary file (the file can be discovered
    from the output message emitted).

    An optional C<:$logger> can be supplied to receive events about what is occurring.

    Returns C<True> if the reporting succeeded.

    =end pod


    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    #| Report basic information about this Candidate to a temp file
    method report(Candidate $candi, Supplier :$logger) {
        my $reporters := self.plugins.grep(*.so).cache;

        my $stdout = Supplier.new;
        my $stderr = Supplier.new;
        if ?$logger {
            $stdout.Supply.grep(*.defined).act: -> $out { $logger.emit({ level => VERBOSE, stage => REPORT, phase => LIVE, candi => $candi, message => $out }) }
            $stderr.Supply.grep(*.defined).act: -> $err { $logger.emit({ level => ERROR,   stage => REPORT, phase => LIVE, candi => $candi, message => $err }) }
        }

        my @reports = $reporters.map: -> $reporter {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => REPORT, phase => START, candi => $candi, message => "Reporting with plugin: {$reporter.^name}" });
            }

            my $report = $reporter.report($candi, :$stdout, :$stderr);
            $report;
        }

        $stdout.done();
        $stderr.done();

        return @reports.grep(*.defined);
    }
}
