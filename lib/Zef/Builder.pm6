use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::PathTools;


class Zef::Builder does Zef::Phase::Building {
    method pre-compile(*@paths is copy) {
        my @results = eager gather for @paths -> $path {
            my $lib      = $*SPEC.catdir($path.IO.path, 'lib').IO;
            my $blib     = $*SPEC.catdir($path.IO.path, 'blib/lib').IO;
            my $blib-cur = CompUnitRepo::Local::File.new($blib.IO.path), 
            my $lib-cur  = CompUnitRepo::Local::File.new($lib.IO.path);
            my @metas    = extract-deps( $lib.IO.ls(:r, :f) );
            my @sources  = Zef::Utils::Depends.new(:@metas).build-dep-tree;

            for @sources -> %module {
                my $out      = "{$*CWD}/blib/{%module<file>.IO.relative}.{$*VM.precomp-ext}";
                my $cu       = CompUnit.new(%module<file>.IO.path);

                "[{%module<file>.IO.relative}] {'.' x 42 - %module<file>.IO.relative.chars} ".print;
                try mkdirs($out.IO.dirname);

                if $cu.precomp($out, :INC($blib-cur, $lib-cur), :force) {
                    $cu = $cu.clone(has-precomp => True); # workaround for precomp-path bug
                    say "OK {$out.IO.relative}";
                }
                else {
                    say "FAILED";
                }

                take $cu;
            }
        }

        return @results;
    }
}
