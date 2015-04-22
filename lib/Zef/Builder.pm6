use Zef::Phase::Building;
use Zef::Depends;
use Zef::Utils;

use JSON::Fast;

class Zef::Builder does Zef::Phase::Building {
    multi method pre-compile(*@paths is copy) {
        my @precompiled;

        while @paths.shift -> $path {
            my @INC =   CompUnitRepo::Local::File.new("$path/blib/lib"), 
                        CompUnitRepo::Local::File.new("$path/lib"),
                        @*INC; # remove this once we figure out how to include installed deps here
                               # without including target module if already installed
            my @sources = Zef::Depends.build(Zef::Utils.comb($*SPEC.catpath('', $path, 'lib')));
            
            for @sources -> $module {
                my $cu = CompUnit.new($module<file>);
                my $out = IO::Path.new("{$*CWD}/blib/{$module<file>.IO.relative}.{$*VM.precomp-ext}");
                $out.IO.dirname.IO.mkdir;
                $out.IO.unlink if $out.IO.e;
 
                my $result = $cu.precomp(:force, $out, :@INC);
                "[{$module<file>.subst(/ $path ['/' || '\\'] /, '')}] {'.' x 77 - $module<file>.chars} ".print;

                if $result { # so just check for the file's existence
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
