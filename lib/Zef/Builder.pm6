use Zef::Phase::Building;
use Zef::Depends;
use JSON::Tiny;

class Zef::Builder does Zef::Phase::Building {

    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            self does ::($p) if do { require ::($p); ::($p).does(Zef::Phase::Building) };
        }
    }

    multi method pre-compile(*@paths is copy) {
        my @precompiled;

        while @paths.shift -> $path {
            my @INC = CompUnitRepo::Local::File.new("$path/lib"), CompUnitRepo::Local::File.new("$path/blib/lib");
            my @sources = Zef::Depends.comb($*SPEC.catpath('', $path, 'lib'));

            for @sources -> $module {
                my $cu = CompUnit.new($module<file>);
                my $out = "{$*CWD}/blib/{$module<file>.IO.relative}.{$*VM.precomp-ext}" andthen .IO.dirname.IO.mkdir;
                $out.IO.unlink if $out.IO.e;
 
                my $result = $cu.precomp(:force, $out, :@INC);
                "[{$module<file>.subst(/ $path ['/' || '\\'] /, '')}] {'.' x 77 - $module<file>.chars} ".print;

                if $result && $out.IO ~~ :e { # so just check for the file's existence
                    @precompiled.push($out.IO);
                    "OK $out".say;
                }
                else {
                    "FAILED".say;
                    die "Failed to compile: $out";
                }
            }
        }

        return @precompiled;
    }
}
