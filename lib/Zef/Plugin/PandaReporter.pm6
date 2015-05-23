use Zef::Phase::Reporting;
use Zef::Utils::PathTools;

try require Panda::Reporter;
try require Panda::Project;


role Zef::Plugin::PandaReporter does Zef::Phase::Reporting {
    if ::('Panda::Reporter') ~~ Failure {
        fail "Need to install Panda (Panda::Reporter) for Plugin::PandaReporter support";
    }
    if ::('Panda::Project') ~~ Failure {
        fail "Need to install Panda (Panda::Project) for Plugin::PandaReporter support";
    }

    # Panda::Reporter's to-json fails to serialize $*KERNEL when used from here for 
    # unknown reasons, so we have to do this:
    has %!kernel = %(
        :name($*KERNEL.name),
        :version($*KERNEL.version.Str),
        :auth($*KERNEL.auth),
        :release($*KERNEL.release),
        :hardware($*KERNEL.hardware),
        :arch($*KERNEL.arch),
        :bits($*KERNEL.bits),
    );


    # For now we match items from @test-results and @build-results
    # to @metas by comparing %_<path> (the root path of the repo)
    method report(*@metas, :@test-results, :@build-results) {
        my @bones = gather for @metas -> $meta-path {
            my $meta-json = from-json($meta-path.IO.slurp);
            my %meta      = %($meta-json);
            my $repo-path = $meta-path.IO.dirname;

            take ::('Panda::Project').new(
                name         => %meta<name>,
                version      => %meta<ver> // %meta<version> // '*',
                dependencies => %meta<depends>.list,
                metainfo     => $meta-json,
                build-passed => ?@build-results.first(-> %b { %b<path> eq $repo-path }).<ok>,
                test-passed  => ?@test-results.first( -> %t { %t<path> eq $repo-path }).<ok>,
                test-output  => '',
                build-output => '',
            );
        }

        my @results = gather for @bones -> $bone {
            state $reports-file = $*SPEC.catpath('', $*SPEC.catdir($*TMPDIR, "p6c-reports"), time).IO andthen {
                try mkdirs($_.dirname);
                try $_.open(:a).close;
            }
            temp %*ENV<PANDA_SUBMIT_TESTREPORTS> = 1;
            ::('Panda::Reporter').new( :$bone, :$reports-file ).submit;
        }
    }
}
