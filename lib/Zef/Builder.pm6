use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::FileSystem;


class Zef::Builder does Zef::Phase::Building {
    method pre-compile(*@paths is copy) {
        my @results;

        while @paths.shift -> $path {
            my $lib     = $*SPEC.catdir($path.IO.path, 'lib').IO;
            my @sources = Zef::Utils::Depends.build(Zef::Utils::FileSystem.extract-deps( $lib ));

            for @sources -> %module {
                my @INC    := CompUnitRepo::Local::File.new("$path/blib/lib"), 
                              CompUnitRepo::Local::File.new("$path/lib"),
                              @*INC; # remove this once we figure out how to include installed deps here
                                     # without including target module if already installed
                my $cu = CompUnit.new(%module<file>);
                my $out = IO::Path.new("{$*CWD}/blib/{%module<file>.IO.relative}.{$*VM.precomp-ext}");
                try mkdirs($out.IO.dirname);
                try unlink($out.IO) if $out.IO.e;
                my $result = $cu.precomp(:force, $out, :@INC);
                "[{%module<file>.subst(/ $path ['/' || '\\'] /, '')}] {'.' x 77 - %module<file>.chars} ".print;

                if $result { # so just check for the file's existence
                    my %r = name => %module<name>, source => %module<file>, precomp => $out.IO;
                    @results.push({ %r });
                    "OK $out".say;
                }
                else {
                    my %r = name => %module<name>, source => %module<file>, error => 'Failed to compile';
                    @results.push({ %r });
                    "FAILED".say;
                }
            }
        }

        return @results;
    }
}
