use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::PathTools;


class Zef::Builder does Zef::Phase::Building {
    method pre-compile(*@paths is copy) {
        my @results := gather for @paths -> $path {
            my $lib     = $*SPEC.catdir($path.IO.path, 'lib').IO;
            my $blib    = $*SPEC.catdir($path.IO.path, 'blib/lib').IO;
            my @metas   = extract-deps( $lib.IO.ls(:r, :f) );
            my @sources = Zef::Utils::Depends.new(:@metas).build-dep-tree;

            for @sources -> %module {
                my @INC    := CompUnitRepo::Local::File.new($blib.IO.path), 
                              CompUnitRepo::Local::File.new($lib.IO.path),
                              @*INC; # remove this once we figure out how to include installed deps here
                                     # without including target module if already installed
                my $cu  = CompUnit.new(%module<file>.IO.path);
                my $out = IO::Path.new("{$*CWD}/blib/{%module<file>.IO.relative}.{$*VM.precomp-ext}");

                try mkdirs($out.IO.dirname);
                my $result = $cu.precomp(:force, $out, :@INC);
                "[{%module<file>.IO.relative}] {'.' x 42 - %module<file>.IO.relative.chars} ".print;

                my %r = %( name     => %module<name>, 
                           source   => %module<file>,
                           ok       => $result ?? 1 !! 0 );

                given $result {
                    when True  { 
                        %r.<precomp> = $out.IO;
                        say $result ?? "OK {$out.IO.relative}" !! "FAILED";
                    }
                    when False { %r.<error> = "Failed to build {%module.<name>}" }
                }

                take {%r};
            }
        }

        return @results;
    }
}
