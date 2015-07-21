use Zef::ProcessManager;
use Zef::Utils::PathTools;

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
                '--ll-exception',  # Cannot be optional yet, as its required for proper test exitcodes with Test.pm
                @includes-as-args, # -Ilib, -I/some/other/path, ...
                $file-rel,         # Use a relative path in conjuncture with
                :cwd($!path),      #    the project's cwd to build our test command.
                :id($file-rel)     # For STDMux to display which file its outputting. todo: extract from Proc's args and delete this
            );
        }
    }

    method start(:$p6flags) {
        if $!pm.processes {
            $!promise = Promise.allof: $!pm.start-all;
        }
        else {
            $!promise = Promise.new;
            $!promise.keep(1);
        }

        $!promise;
    }

    method tap(&code) { $!pm.tap-all(&code) }

    method ok { $!pm>>.ok }

    method nok { ?$.ok() ?? False !! True }

    method passes {
        $!pm.processes.list.grep(*.ok.so)>>.id;
    }

    method failures {
        $!pm.processes.list.grep(*.ok.not)>>.id;
    }
}

