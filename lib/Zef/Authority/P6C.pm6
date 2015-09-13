use Zef::Authority::Net;
use Zef::Net::HTTP::Client;
use Zef::Utils::Depends;
use Zef::Utils::Git;

our @skip = <Test MONKEY-TYPING MONKEY_TYPING nqp v6 NativeCall>;

# perl6 community ecosystem + test reporting
class Zef::Authority::P6C does Zef::Authority::Net {
    has $!ua      = Zef::Net::HTTP::Client.new;
    has $!git     = Zef::Utils::Git.new;
    has @!mirrors = <http://ecosystem-api.p6c.org/projects.json>;

    method update-projects {
        my $response = $!ua.get: ~@!mirrors.pick(1);
        my $content  = $response.content or fail "!!!> Failed to update projects file";
        my $json     = from-json($content);
        @!projects   = try { $json.cache }\
            or fail "!!!> Missing or invalid projects json";
    }

    # Use the p6c hosted projects.json to get a list of name => git-repo that 
    # can then be fetched with Utils::Git
    method get(
        Zef::Authority::P6C:D: 
        *@wants,
        :@ignore,
        :$save-to is copy,
        Bool :$depends,
        Bool :$test-depends,
        Bool :$build-depends,
        Bool :$fetch = True,
    ) {
        self.update-projects if $fetch && !@!projects.elems;
        my @wants-dists = @!projects.grep({ $_.<name> ~~ any(@wants) }).cache;

        my @wants-dists-filtered = !@ignore ?? @wants-dists !! @wants-dists.grep({
               (!$depends       || any($_.<depends>.cache.grep(*.so))       ~~ none(@ignore.grep(*.so)))
            && (!$test-depends  || any($_.<build-depends>.cache.grep(*.so)) ~~ none(@ignore.grep(*.so)))
            && (!$build-depends || any($_.<test-depends>.cache.grep(*.so))  ~~ none(@ignore.grep(*.so)))
        });

        return () unless @wants-dists-filtered;

        # Determine the distribution dependencies we want/need
        my $levels = ?$depends
            ?? Zef::Utils::Depends.new(:@!projects).topological-sort( @wants-dists-filtered, 
                :$depends, :$build-depends, :$test-depends)
            !! @wants-dists-filtered.map({ $_.hash.<name> });

        # Try to fetch each distribution dependency
        eager gather for $levels -> $level {
            for $level.cache -> $package-name {
                next if $package-name.lc ~~ any(@skip>>.lc);
                # todo: filter projects by version/auth
                my %dist = @!projects.cache.first({ $_.<name>.lc eq $package-name.lc }).hash;
                die "!!!> No source-url for $package-name (META info lost?)" and next unless ?%dist<source-url>;

                # todo: implement the rest of however github.com transliterates paths
                my $basename  = %dist<name>.trans(':' => '-');
                temp $save-to  = ~$save-to.IO.child($basename);
                my @git       = $!git.clone(:$save-to, %dist<source-url>).cache;

                take { :unit-id(%dist.<name>), :path(@git.[0].<path>), :ok(?$save-to.IO.e) }
            }
        }
    }

    # todo: refactor into Zef::Roles::
    method report(*@metas, :@test-results, :@build-results) {
        eager gather for @metas -> $meta-path {
            my $meta-json = from-json($meta-path.IO.slurp);
            my %meta      = %($meta-json);
            my $repo-path = $meta-path.IO.parent;

            my $test  = @test-results.first: { $_.path.IO.ACCEPTS($repo-path.IO) }
            my $build = @build-results.first: { $_.path.IO.ACCEPTS($repo-path.IO) }

            # the GLR transitions is making this this string concating
            # look more complicated than it needs to be
            my $build-output;
            for $build.processes.cache -> $group {
                for $group.cache -> $item {
                    for $item.cache -> $proc {
                        with $proc.stdmerge -> $out {
                            $build-output ~= "{$out}\n";
                        }
                    }
                }
            }
            my $test-output;
            for $test.processes.cache -> $group {
                for $group.cache -> $item {
                    for $item.cache -> $proc {
                        with $proc.stdmerge -> $out {
                            $test-output ~= "{$out}\n";
                        }
                    }
                }
            }

            # See Panda::Reporter
            my $report = to-json {
                :name(%meta<name>),
                :version(%meta<ver> // %meta<version> // '*'),
                :dependencies(%meta<depends>),
                :metainfo($meta-json),
                :build-output($build-output // ''),
                :test-output($test-output   // ''),
                :build-passed(?$build.processes.elems ?? (?$build.passes.elems && !$build.failures.elems) !! Nil),
                :test-passed(?$test.processes.elems   ?? (?$test.passes.elems  && !$test.failures.elems ) !! Nil),
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

            my $report-id = try {
                CATCH { default { print "===> Error while POSTing: $_" }}
                my $response = $!ua.post("http://testers.perl6.org/report", body => $report);
                my $body     = $response.content(:bin).decode('utf-8');
                ?$body.match(/^\d+$/) ?? $body.match(/^\d+$/).Str !! 0;
            }

            take {
                ok        => ?$report-id,
                unit-id   => %meta<name>,
                report    => $report,
                report-id => $report-id // '',
            }
        }
    }
}
