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
        my @dirs = @paths.map({CompUnitRepo::Local::File.new($*SPEC.catpath('', $_, 'lib')), CompUnitRepo::Local::File.new($*SPEC.catpath('', $_, 'blib'));});
        my @modules;
        my @precompiled;
        my %retry-me;

        for @paths.shift -> $path {
            @modules = Zef::Depends.comb($*SPEC.catpath('', $path, 'lib'));
            for @modules -> $module {
                my $cu = CompUnit.new($module<file>);

                my $out = $path.IO.resolve;
                $out ~= $module<file>.subst($out, '/blib') ~ ".{$*VM.precomp-ext}";
                mkdir $out.IO.dirname;
                my $result = $cu.precomp(:force, $out, :INC(@dirs, @*INC));

                "[{$module<file>.subst(/ $path ['/' || '\\'] /, '')}] {'.' x 77 - $module<file>.chars} ".print;

                if $result && $out.IO ~~ :e { # so just check for the file's existence
                    @precompiled.push($out.IO);
                    "OK".say;
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
