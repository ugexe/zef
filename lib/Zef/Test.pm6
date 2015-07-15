use Zef::ProcessManager;
use Zef::Utils::PathTools;
require Zef::Test::Helper;

class Zef::Test {
    has $.pm;
    has $.path;
    has @.includes;
    has $.promise;
    has $.async;
    has $.shuffle;

    submethod BUILD(:$!path!, :@!includes, Bool :$!async, :$!pm, :$!shuffle) {
        my $test-dir   = $!path.IO.child('t');
        my @test-files = $test-dir.ls(:r, :f).grep(*.extension eq 't');
        @test-files = ?$!shuffle ?? @test-files.pick(*) !! @test-files.sort;

        $!pm = !$!pm.defined ?? Zef::ProcessManager.new(:$!async)
                             !! $!pm.DEFINITE
                                ?? $!pm
                                !! ::($!pm).new;

        my @includes-as-args = @!includes.map({ qqw/-I$_/ });

        for @test-files -> $file {
            # Many tests are (incorrectly) written with the assumption the cwd is their projects base directory.
            my $file-rel = ?$file.IO.is-relative ?? $file.IO.relative !! $file.IO.relative($!path);

            $!pm.create(
                $*EXECUTABLE, 
                @includes-as-args,
                $file-rel, 
                :cwd($!path), 
                :id($file-rel) 
            );
        }
    }

    method start(:$p6flags) {
        if $!pm.processes {
            $!pm.start-all;
            $!promise = Promise.allof: $!pm.processes.map({ $_.promise });
        }
        else {
            $!promise = Promise.new;
            $!promise.keep(1);
        }

        $!promise;
    }

    method tap(&code) { $!pm.tap-all(&code) }

    method ok { $!pm.ok-all }

    method nok { ?$.ok() ?? False !! True }

    method passes {
        $!pm.processes.list.grep(*.ok.so)>>.id;
    }

    method failures {
        $!pm.processes.list.grep(*.ok.not)>>.id;
    }
}

