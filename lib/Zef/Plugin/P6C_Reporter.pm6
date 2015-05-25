use Zef::Phase::Reporting;
use Zef::Utils::HTTPClient;
use Zef::Utils::PathTools;


role Zef::Plugin::P6C_Reporter does Zef::Phase::Reporting {
    # For now we match items from @test-results and @build-results
    # to @metas by comparing %_<path> (the root path of the repo).
    # Probably a good spot to use a .classify
    method report(*@metas, :@test-results, :@build-results) {
        my @bones = gather for @metas -> $meta-path {
            my $meta-json = from-json($meta-path.IO.slurp);
            my %meta      = %($meta-json);
            my $repo-path = $meta-path.IO.dirname;

            my %test  = @test-results.first({ $_<path> eq $repo-path }).hash;
            my %build = @build-results.first({ $_<path> eq $repo-path }).hash;

            my $build-output = %build.<curlfs>.map(-> $cu { $cu.build-output }).join("\n");
            my $test-output  = %test.<tests>.map({ $_<test-output> }).join("\n");

            take to-json {
                :name(%meta<name>),
                :version(%meta<ver> // %meta<version> // '*'),
                :dependencies(%meta<depends>),
                :metainfo($meta-json),
                :build-output($build-output),
                :build-passed(?%build<ok>),
                :test-output($test-output),
                :test-passed(?%test<ok>),
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
            }
        }

        my $client = Zef::Utils::HTTPClient.new;
        my @submissions = gather for @bones -> $bone {
            my $response  = $client.post("http://testers.perl6.org/report", payload => $bone);
            my $report-id = $response.body;
            say "==> Report location: http://testers.perl6.org/reports/$report-id.html";
        }
    }
}
