use Zef::Phase::Building;
# todo: turn this into a panda compatability thing

role Zef::Plugin::PreComp does Zef::Phase::Building {
    multi method pre-compile(*@paths) {
        my @precompiled;

        my $supply = Supply.new;
        $supply.act: {
            given $_.IO {
                when :d {
                    dir($_).map: -> $d { $supply.emit($d) };
                } 
                when :f & /\.pm6?$/ {
                    my $dest = "blib/{$_.relative}.{$*VM.precomp-ext}".IO.path;
                    mkdir($dest.IO.dirname) or fail "couldnt mkdir" ;
                    my $cmd  = "$*EXECUTABLE -Ilib --target={$*VM.precomp-target} --output=$dest $_";
                    say $cmd;
                    my $precomp = shell($cmd).exit == 0 ?? True  !! False;

                    $dest.IO.e 
                        ?? @precompiled.push($*SPEC.catdir($*CWD,$dest)) && "precomp ok".say 
                        !! "precomp not ok".say;
                }
            }
        }

        await @paths.map: { $supply.emit($_) };

        return @precompiled;
    }
}
