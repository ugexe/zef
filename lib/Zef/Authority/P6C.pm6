use Zef::Authority::Net;
use Zef::Net::HTTP::Client;
use Zef::Utils::Depends;
use Zef::Utils::Git;

class Zef::Authority::P6C does Zef::Authority::Net {
    has $!ua      = Zef::Net::HTTP::Client.new;
    has $!git     = Zef::Utils::Git.new;
    has @!mirrors = <http://ecosystem-api.p6c.org/projects.json>;


    method update-projects {
        my $response = $!ua.get: @!mirrors.[0];
        @!projects = @(from-json($response.content));
    }

    method get(Zef::Authority::P6C:D: *@wants, :$save-to is copy = $*TMPDIR) {
        ENTER self.update-projects;
        my @wants-metas = @!projects.grep({ $_.<name> ~~ any(@wants) }); # unused now?
        my @tree        = build-dep-tree( @!projects, target => $_ ) for @wants-metas;
        my @results     = eager gather for @tree -> %node {
            say "Getting: {%node.<source-url>}";
            my $basename   = %node.<name>.trans(':' => '-');
            temp $save-to  = $*SPEC.catdir($save-to, $basename);
            my @git        = $!git.clone(:$save-to, %node.<source-url>);
            take { module => %node.<name>, path => @git.[0].<path>, ok => ?$save-to.IO.e }
        }
        return @results;
    }


    method report(*@metas, :@test-results, :@build-results) {
        my @meta-reports = gather for @metas -> $meta-path {
            my $meta-json = from-json($meta-path.IO.slurp);
            my %meta      = %($meta-json);
            my $repo-path = $meta-path.IO.dirname;
            KEEP take { %meta }

            my $test  = @test-results.list>>.results.grep({ $_.list>>.file.IO.absolute ~~ /^$repo-path/ });
            my %build = @build-results.first({ $_<path> eq $repo-path }).hash;

            my $build-output = %build.<curlfs>.map(-> $cu { $cu.build-output }).join("\n");
            my $test-output  = $test>>.list.map({ $_.list>>.output }).join("\n");

            # See Panda::Reporter
            %meta<report> = to-json {
                :name(%meta<name>),
                :version(%meta<ver> // %meta<version> // '*'),
                :dependencies(%meta<depends>),
                :metainfo($meta-json),
                :build-output($build-output),
                :build-passed(?%build<ok>),
                :test-output($test-output),
                :test-passed(?all(?$test>>.list>>.ok)),
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

        my @submissions = gather for @meta-reports -> $m {
            KEEP take { ok => 1, module => $m<name>, report => $m<report> }
            UNDO take { ok => 0, module => $m<name>, report => $m<report> }
            my $response  = $!ua.post("http://testers.perl6.org/report", payload => $m<report>);
            my $report-id = $response.body;
            say "===> Report location: http://testers.perl6.org/reports/$report-id.html";
        }
    }
}
