use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::PathTools;


class Zef::Builder does Zef::Phase::Building {
    method pre-compile(*@paths is copy) {
        my @results = eager gather for @paths -> $path {
            my CompUnitRepo::Local::File $lib-cur  .= new: $*SPEC.catdir($path.IO.path, 'lib').IO;
            my CompUnitRepo::Local::File $blib-cur .= new: $*SPEC.catdir($path.IO.path, 'blib/lib').IO;
            my @metas    = extract-deps( $lib-cur.IO.ls(:r, :f) );
            my @sources  = Zef::Utils::Depends.new(:@metas).build-dep-tree;

            for @sources -> %module {
                my $out      = "{$*CWD}/blib/{%module<file>.IO.relative}.{$*VM.precomp-ext}";
                my $cu       = CompUnit.new(%module<file>.IO.path);
                $cu does role { # workaround for non-default :$out
                    has $!has-precomp;
                    has $!out;
                    submethod BUILD { 
                        $!out = $out; 
                        $!has-precomp := ?$!out.IO.f;
                    }
                    method precomp-path { $!out.IO.absolute       }
                }

                given %module<file>.IO.relative { print "[{$_}] {'.' x 42 - $_.chars} " }

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
