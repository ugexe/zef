use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::PathTools;


class Zef::Builder does Zef::Phase::Building {
    method pre-compile(*@paths is copy) {
        my @results = eager gather for @paths -> $path {
            my $lib     = $*SPEC.catdir($path.IO.path, 'lib').IO;
            my $blib    = $*SPEC.catdir($path.IO.path, 'blib/lib').IO;
            my @metas   = extract-deps( $lib.IO.ls(:r, :f) );
            my @sources = Zef::Utils::Depends.new(:@metas).build-dep-tree;

            for @sources -> %module {
                my @INC    := CompUnitRepo::Local::File.new($blib.IO.path), 
                              CompUnitRepo::Local::File.new($lib.IO.path),
                              @*INC; # remove this once we figure out how to include installed deps here
                                     # without including target module if already installed
                my $cu = CompUnit.new(%module<file>.IO.path);
                my $precomp-path = IO::Path.new("{$*CWD}/blib/{%module<file>.IO.relative}.{$*VM.precomp-ext}");

                try mkdirs($precomp-path.IO.dirname);
                my $result = $cu.precomp($precomp-path, :@INC, :force);
                "[{%module<file>.IO.relative}] {'.' x 42 - %module<file>.IO.relative.chars} ".print;

                my %r = %( name     => %module<name>, 
                           source   => %module<file>,
                           ok       => $result ?? 1 !! 0 );

                given $result {
                    when True  { 
                        %r.<precomp> = $precomp-path.IO;
                        say $result ?? "OK {$precomp-path.IO.relative}" !! "FAILED";
                    }
                    when False { %r.<error> = "Failed to build {%module.<name>}" }
                }

                take {%r};
            }
        }

        return @results;
    }
}
