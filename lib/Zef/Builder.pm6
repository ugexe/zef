use Zef::Phase::Building;
use JSON::Tiny;

class Zef::Builder does Zef::Phase::Building {

    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            self does ::($p) if do { require ::($p); ::($p).does(Zef::Phase::Building) };
        }
    }

    multi method pre-compile(*@paths) {
        my $supply = Supply.new;
        $supply.act: {
            given $_.IO {
                when :d {
                    dir($_).map: -> $d { $supply.emit($d) };
                } 
                when :f & /\.pm6?$/ {
                    my $precomp-path = $_.path ~ '.' ~ $*VM.precomp-ext;
                    unlink $precomp-path if $precomp-path.IO.e;
                    my $curlf = CompUnit.new($_.path).precomp;
                    say $precomp-path.IO.e ?? "ok" !! "not ok";

                    CATCH { default { say "Error: $_" } }
                }
            }
        }

        my $promise = await @paths.map: { 
            temp %*ENV<PERL6LIB> = $_.IO.path;
            # temp %*ENV<RAKUDO_PRECOMP_WITH> = $_;

            $supply.emit($_);
        };
    }
}