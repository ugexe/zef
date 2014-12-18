use Zef::Phase::Building;
role Zef::Plugin::PreComp does Zef::Phase::Building {
    multi method pre-compile($path) {
        # todo: compile to temp directory, delete old blib if exists, 
        # then rename temp to blib and move (so we don't) delete old 
        # blib if everything doesn't compile...?
        say "path: $path";
        my $supply = Supply.new;
        $supply.act: {
            if $_.IO.d {
                for dir($_) -> $dir {
                    $supply.emit($dir);
                }
            } 
            elsif $_.IO ~~ :f {
                say "found file: $_";
                my $dest = "blib/{$_.dirname}/{$_.basename}.{$*VM.precomp-ext}";
                fail "couldnt mkdir" unless mkdir($dest.IO.dirname);
                my $cmd  = "$*EXECUTABLE -Ilib --target={$*VM.precomp-target} --output=$dest $_";
                say "shell: $cmd";
                my $precomp = shell($cmd).exit == 0 ?? True  !! False;

                CATCH { default { say "Error: $_" } }
            }
        }

        my $promise = await $supply.emit($path);
        say "done";
    }
}

