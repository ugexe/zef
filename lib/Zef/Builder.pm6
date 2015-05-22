use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::PathTools;


class Zef::Builder does Zef::Phase::Building {
    # todo: lots of cleanup/refactoring
    method pre-compile(*@paths is copy, :$save-to is copy) {
        my @blibs;
        my @results = eager gather for @paths -> $path {
            temp $save-to //= $path;
            my %meta     = %(from-json( $*SPEC.catpath('', $path, 'META.info').IO.slurp) );
            my @provides = %meta<provides>.list;
            
            my @libs     = @provides.map({
                $*SPEC.rel2abs($*SPEC.splitdir($_.value.IO.dirname).[0].IO, $path)
            }).unique.map({ CompUnitRepo::Local::File.new($_) });
            @blibs.push($_) for @libs.map({ 
                CompUnitRepo::Local::File.new( $*SPEC.rel2abs($*SPEC.catdir('blib', $*SPEC.abs2rel($_, $path)), $path) );
            });
            my $INC     := @blibs.unique, @libs, @*INC;
            
            my @files    = @provides.map({ $*SPEC.rel2abs($_.value, $path).IO.path });
            my @deps     = extract-deps( @files );
            my @ordered  = build-dep-tree( @deps );

            my @compiled = @ordered.map({
                print "[{$_.<path>}] {'.' x 42 - $_.<path>.chars} ";

                my $blib-file := $*SPEC.rel2abs($*SPEC.catdir('blib', $*SPEC.abs2rel($_.<path>, $path)).IO, $path).IO;
                my $out       := $*SPEC.rel2abs($*SPEC.catpath('', $blib-file.IO.dirname, "{$blib-file.IO.basename}.{$*VM.precomp-ext}"));
                my $cu        := CompUnit.new( $_.<path> );
                $cu does role { # workaround for non-default :$out
                    has $!has-precomp;
                    has $!out;
                    submethod BUILD { 
                        $!out         := $out; 
                        $!has-precomp := ?$!out.IO.f;
                    }
                    method precomp-path { $!out.IO.absolute }
                }

                try mkdirs($cu.precomp-path.IO.dirname);

                say (my $result = $cu.precomp($out, :$INC, :force))
                    ?? "ok: {$cu.precomp-path}" 
                    !! "FAILED: {$cu.precomp-path}";
                $cu;
            });
            take { precomp-path => @blibs[0], path => $path, curlfs => @compiled, sources => @provides }
        }

        return @results;
    }
}
