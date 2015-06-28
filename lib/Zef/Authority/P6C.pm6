use Zef::Authority::Net;
use Zef::Net::HTTP::Client;
use Zef::Utils::Depends;
use Zef::Utils::Git;


# perl6 community ecosystem + test reporting
class Zef::Authority::P6C does Zef::Authority::Net {
    has $!ua      = Zef::Net::HTTP::Client.new;
    has $!git     = Zef::Utils::Git.new;
    has @!mirrors = <http://ecosystem-api.p6c.org/projects.json>;


    method update-projects {
        my $response = $!ua.get: @!mirrors.[0];
        @!projects = try @(from-json($response.content)).grep({ ?$_.<name> });
    }

    # Use the p6c hosted projects.json to get a list of name => git-repo that 
    # can then be fetched with Utils::Git
    method get(
        Zef::Authority::P6C:D: 
        *@wants,
        :$save-to is copy,
        Bool :$skip-depends,
    ) {
        self.update-projects unless @!projects;
        my @wants-dists = @!projects.grep({ $_.<name> ~~ any(@wants) });

        # Determine the distribution dependencies we want/need
        my @levels = $skip-depends
            ?? @wants-dists.map({ $_.hash.<name> })
            !! Zef::Utils::Depends.new(:@!projects).topological-sort(@wants-dists);

        # Try to fetch each distribution dependency
        my @results = eager gather for @levels -> $level {
            for $level.list -> $package-name {
                # todo: filter projects by version/auth
                my %dist = @!projects.first({ $_.<name> eq $package-name }).hash;
                say "Getting: {%dist.<source-url>}";

                # todo: implement the rest of however github.com transliterates paths
                my $basename   = %dist.<name>.trans(':' => '-');
                temp $save-to  = $*SPEC.catdir($save-to, $basename);
                my @git        = $!git.clone(:$save-to, %dist.<source-url>);

                take { 
                    module => %dist.<name>, 
                    path   => @git.[0].<path>, 
                    ok     => ?$save-to.IO.e
                }
            }
        }

        return @results;
    }


    method report(*@metas, :@test-results, :@build-results) {
        my @meta-reports = gather for @metas -> $meta-path {
            my $meta-json = from-json($meta-path.IO.slurp);
            my %meta      = %($meta-json);
            my $repo-path = $meta-path.IO.dirname;
            KEEP take { %meta }

            my $test  = @test-results.list>>.results.grep({ $_.list>>.file.IO.absolute.starts-with($repo-path) });
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

        my @submissions = eager gather for @meta-reports -> $m {
            my $response  = $!ua.post("http://testers.perl6.org/report", body => $m<report>);
            my $body      = $response.content;

            # P6C reponse body to a successful report submission is just the ID of the report
            my $report-id = ?$body.match(/^\d+$/) ?? $body.match(/^\d+$/).Str !! 0;

            take {
                ok     => ?$report-id, 
                module => $m.<name>, 
                report => $m.<report>,
                id     => $report-id,
            }
        }
    }
}
