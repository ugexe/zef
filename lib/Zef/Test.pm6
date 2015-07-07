use Zef::Test::Process;
use Zef::Utils::PathTools;

class Zef::Test {
    has $.path;
    has @.includes;
    has @.processes;
    has $.promise;

    submethod BUILD(:$!path!, :@!includes) {
        my $test-dir   = $*SPEC.catdir($!path, 't').IO;
        my @test-files = $test-dir.IO.ls(:r, :f).grep(*.extension eq 't');

        @!processes = eager gather for @test-files -> $file {
            take Zef::Test::Process.new( :$file, :@!includes, cwd => $!path );
        }
    }

    method start(:$p6flags) {
        @!processes>>.start;
        $!promise = Promise.allof( @!processes>>.promise );
    }

    method ok {
        all(@!processes>>.ok) ?? True !! False;
    }

    method nok {
        self.ok ?? False !! True;
    }

    method passes {
        @!processes.grep(*.ok.so)>>.path;
    }

    method failures {
        @!processes.grep(*.ok.not)>>.path;
    }
}

