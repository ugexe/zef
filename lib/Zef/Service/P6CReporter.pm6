use v6;
use Zef;

class Zef::Service::P6CReporter does Messenger does Reporter {

    method report($event) {
        # TODO: put this into the plugin architecture
        state $probe = (try require Net::HTTP::POST) !~~ Nil ?? True !! False;
        once { say "!!!> Install Net::HTTP to enable p6c test reporting" unless $probe }
        if $probe {
            my $candi := $event.<payload>;

            my $report-json = to-json({
                :name($candi.dist.name),
                :version(first *.defined, $candi.dist.meta<ver version>),
                :dependencies($candi.dist.meta<depends>),
                :metainfo($candi.dist.meta.hash),
                :build-output($candi.^find_method('build-results') ?? $candi.build-results.Str !! Str),
                :build-passed($candi.^find_method('build-results') ?? $candi.build-results.map(*.so).all.so !! True),
                :test-output($candi.^find_method('test-results') ?? $candi.test-results.Str !! Str),
                :test-passed($candi.^find_method('test-results') ?? $candi.test-results.map(*.so).all.so !! True),
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
                    :name($*PERL.name),
                    :version($*PERL.version.Str),
                    :auth($*PERL.auth),
                    :compiler({
                        :name($*PERL.compiler.name),
                        :version($*PERL.compiler.version.Str),
                        :auth($*PERL.compiler.auth),
                        :release($*PERL.compiler.release),
                        :build-date($*PERL.compiler.build-date.Str),
                        :codename($*PERL.compiler.codename),
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

            my $response = ::('Net::HTTP::POST')("http://testers.perl6.org/report", body => $report-json.encode);
            my $test-id  = try { $response.content(:force).Int };

            $test-id
                ?? $.stdout.emit("Report for {$candi.dist.identity} will be available at http://testers.p6c.org/reports/{$test-id}.html")
                !! $.stderr.emit("Encountered problems sending test report for {$event<payload>.dist.identity}");

            return $test-id;
        }
    }
}

