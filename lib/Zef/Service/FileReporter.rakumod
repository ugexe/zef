use Zef:ver($?DISTRIBUTION.meta<version>):api($?DISTRIBUTION.meta<api>):auth($?DISTRIBUTION.meta<auth>);

class Zef::Service::FileReporter does Reporter {

    =begin pod

    =title class Zef::Service::FileReporter

    =subtitle A basic save-to-file based implementation of the Reporter interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Distribution::Local;
        use Zef::Service::FileReporter;

        my $reporter = Zef::Service::FileReporter.new;

        # Add logging if we want to see output
        my $stdout = Supplier.new;
        my $stderr = Supplier.new;
        $stdout.Supply.tap: { say $_ };
        $stderr.Supply.tap: { note $_ };

        # Assuming our current directory is a raku distribution
        my $dist = Zef::Distribution::Local.new($*CWD);
        my $candidate = Candidate.new(:$dist);
        my $reported = so $reporter.report($candidate, :$stdout, :$stderr);
        say $reported ?? "Report Success" !! "Report Failure";

    =end code

    =head1 Description

    C<Reporter> class that serves as an example of a reporter.

    Note this doesn't yet save e.g. test output in a way that can be recorded, such as attaching it to
    C<Candidate> or to a temp file linked to that C<Candidate>.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Always returns C<True> since this is backed by C<IO::Path>.

    =head2 method report

        method report(Candidate $candi, Supplier $stdout, Supplier $stderr --> Bool:D)

    Given C<$candi> it will save various information including the distribution meta data, system information,
    if the tests passed, and (in the future, so nyi) test output. A C<Supplier> can be supplied as C<:$stdout>
    and C<:$stderr> to receive any output.

    Returns C<True> if the report data was saved successfully.

    =end pod


    method probe(--> Bool:D) { return True }

    method report(Candidate $candi, Supplier :$stdout, Supplier :$stderr) {
        my $report-json = Zef::to-json(:pretty, {
            :name($candi.dist.name),
            :version(first *.defined, $candi.dist.meta<ver version>),
            :dependencies($candi.dist.meta<depends>),
            :metainfo($candi.dist.meta.hash),
            :build-passed($candi.build-results.map(*.not).none.so),
            :test-passed($candi.test-results.map(*.not).none.so),
            :distro({
                :name($*DISTRO.name),
                :version($*DISTRO.version.Str),
                :auth($*DISTRO.auth),
                :release($*DISTRO.release),
            }),
            :kernel({
                :name($*KERNEL.name),
                :version($*KERNEL.version.Str),
                :auth($*KERNEL.auth),
                :release($*KERNEL.release),
                :hardware($*KERNEL.hardware),
                :arch($*KERNEL.arch),
                :bits($*KERNEL.bits),
            }),
            :perl({
                :name($*RAKU.name),
                :version($*RAKU.version.Str),
                :auth($*RAKU.auth),
                :compiler({
                    :name($*RAKU.compiler.name),
                    :version($*RAKU.compiler.version.Str),
                    :auth($*RAKU.compiler.auth),
                    :release($*RAKU.compiler.release),
                    :codename($*RAKU.compiler.codename),
                }),
            }),
            :vm({
                :name($*VM.name),
                :version($*VM.version.Str),
                :auth($*VM.auth),
                :config($*VM.config),
                :properties($*VM.?properties),
                :precomp-ext($*VM.precomp-ext),
                :precomp-target($*VM.precomp-target),
                :prefix($*VM.prefix.Str),
            }),
        });

        my $out-file = $*TMPDIR.add("zef-report_{rand}");

        try {
            CATCH {
                default {
                    $stderr.emit("Encountered problems sending test report for {$candi.dist.identity}");
                    return False;
                }
            }

            $out-file.spurt: $report-json;

            $stdout.emit("Report for {$candi.dist.identity} will be available at {$out-file.absolute}");
        }

        return $out-file.e;
    }
}

