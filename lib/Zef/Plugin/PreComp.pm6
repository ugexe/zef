use Zef::Phase::Building;
role Zef::Plugin::PreComp does Zef::Phase::Building {
    # todo: allow explicit VM target (and use appropriate exension)
    multi method pre-compile($path) {
        # todo: compile to temp directory, delete old blib if exists, 
        # then rename temp to blib and move (so we don't) delete old 
        # blib if everything doesn't compile...?
        my $supply = Supply.new;
        $supply.act: {
            given $_.IO {
                when :d {
                    for dir($_) -> $dir {
                        $supply.emit($dir);
                    }
                } 
                when :f {
                    my $dest = "blib/{$_.dirname}/{$_.basename}.{$*VM.precomp-ext}";
                    fail "couldnt mkdir" unless mkdir($dest.IO.dirname);
                    my $cmd  = "$*EXECUTABLE -Ilib --target={$*VM.precomp-target} --output=$dest $_";
                    my $precomp = shell($cmd).exit == 0 ?? True  !! False;

                    CATCH { default { say "Error: $_" } }
                }
            }
        }

        # todo: check all exit values in supplu and throw appropriate exceptions if needed
        # as sometimes we may be able to build groups of modules in paralell (todo: build order)
        my $promise = await $supply.emit($path);
    }
}

