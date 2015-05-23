use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::PathTools;


class Zef::Builder does Zef::Phase::Building {
    # todo: lots of cleanup/refactoring
    method pre-compile(*@paths is copy, :$save-to is copy) {
        my @blibs;
        my @results = eager gather for @paths -> $path {
            temp $save-to = $save-to ?? $*SPEC.catdir($save-to, $path).IO !! $path;
            say "==> Build directory: {$save-to.IO.absolute}";
            my %meta     = %(from-json( $*SPEC.catpath('', $path, 'META.info').IO.slurp) );
            my @provides = %meta<provides>.list;
            
            my @libs     = @provides.map({
                $*SPEC.rel2abs($*SPEC.splitdir($_.value.IO.dirname).[0].IO, $path)
            }).unique.map({ CompUnitRepo::Local::File.new($_) });
            @blibs.push($_) for @libs.map({ 
                CompUnitRepo::Local::File.new( $*SPEC.rel2abs($*SPEC.catdir('blib', $*SPEC.abs2rel($_, $path)), $save-to) ).Str;
            });
            my $INC     := @blibs.unique, @libs, @*INC;

            my @files    = @provides.map({ $*SPEC.rel2abs($_.value, $path).IO.path });
            my @deps     = extract-deps( @files );
            my @ordered  = build-dep-tree( @deps );

            my @compiled = @ordered.map({
                my $display-path = $*SPEC.abs2rel($_.<path>, $path);
                print "[{$display-path}] {'.' x 42 - $display-path.chars} ";
                my $blib-file := $*SPEC.rel2abs($*SPEC.catdir('blib', $*SPEC.abs2rel($_.<path>, $path)).IO, $save-to).IO;
                my $out       := $*SPEC.rel2abs($*SPEC.catpath('', $blib-file.IO.dirname, "{$blib-file.IO.basename}.{$*VM.precomp-ext}"), $save-to);
                my $cu        := CompUnit.new( $_.<path> );
                try mkdirs($blib-file.IO.dirname);
                $cu does role { # workaround for non-default :$out
                    has $!has-precomp;
                    has $!out;
                    submethod BUILD { 
                        $!out         := $out; 
                        $!has-precomp := ?$!out.IO.f;
                    }
                    method precomp-path { $!out.IO.absolute }
                }

                mkdirs($cu.precomp-path.IO.dirname);
                say (my $result = $cu.precomp($out, :$INC, :force))
                    ?? "ok: {$*SPEC.abs2rel($cu.precomp-path, $save-to)}" 
                    !! "FAILED";
                $cu;
            });
            take {  
                ok           => ?(@compiled.elems == @provides.elems),
                precomp-path => @blibs[0], 
                path         => $path, 
                curlfs       => @compiled, 
                sources      => @provides 
            }
        }

        return @results;
    }
}
