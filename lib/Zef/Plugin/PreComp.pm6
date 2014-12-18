use Zef::Phase::Building;
role Zef::Plugin::PreComp does Zef::Phase::Building {
    multi method pre-compile($path is copy) {
        say "path: $path";
        my $supply = Supply.new;
        $supply.act: {
            if $_.IO ~~ :d {
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
            }
        }

        my $promise = $supply.emit($path);
        await $promise;
        say "done";
    }
}

