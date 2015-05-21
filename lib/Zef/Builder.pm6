use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::PathTools;


class Zef::Builder does Zef::Phase::Building {
    method pre-compile(*@paths is copy, :$save-to is copy) {
        my @results = eager gather for @paths -> $path {
            $save-to //= $path;
            my $lib  := $*SPEC.catdir($path.IO.path, 'lib').IO;
            my $blib := $*SPEC.catdir($save-to.IO.path, $*SPEC.catdir('blib','lib').IO).IO;
            my @metas    := extract-deps( $lib.IO.ls(:r, :f) );
            my @sources  := Zef::Utils::Depends.new(:@metas).build-dep-tree;

            for @sources -> %module {
                my $lib-cur  := CompUnitRepo::Local::File.new( $lib  );
                my $blib-cur := CompUnitRepo::Local::File.new( $blib );

                my $out := "{$save-to}/blib/{%module<path>.IO.relative}.{$*VM.precomp-ext}";
                my $cu  := CompUnit.new(%module<path>.IO.path);
                $cu does role { # workaround for non-default :$out
                    has $!has-precomp;
                    has $!out;
                    submethod BUILD { 
                        $!out := $out; 
                        $!has-precomp := ?$!out.IO.f;
                    }
                    method precomp-path { $!out.IO.absolute }
                }

                given %module<path>.IO.relative { print "[{$_}] {'.' x 42 - $_.chars} " }

                try mkdirs($cu.precomp-path.IO.dirname);
                say (my $result = $cu.precomp($out, :INC($blib-cur, $lib-cur), :force))
                    ?? "ok: {$cu.precomp-path.IO.relative}" 
                    !! "FAILED: {$cu.precomp-path.IO.relative}";

                take $cu;
            }
        }

        return @results;
    }
}
