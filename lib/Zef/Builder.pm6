use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::PathTools;

# Allows the use of non-default precomp paths i.e. blib/lib prefixes
class CompUnit::Ext is CompUnit {
    has $.out;
    has $.has-precomp;

    method precomp-path { $!out.IO.absolute // nextsame }
    method precomp(CompUnit:D: $out = self.precomp-path, |c) {
        my $file := IO::Path.new-from-absolute-path($out.IO.absolute);
        say "FILE: {$file.perl}";
        $!has-precomp //= ?$file.IO.f;
        $!out = $file;
        nextsame;
        POST {
            $!out = $file;
            say "PRECOMP-PATH: {$file.perl}";
            $!has-precomp   = ?$file.IO.e;
        }
    }
}

class Zef::Builder does Zef::Phase::Building {
    # todo: lots of cleanup/refactoring
    method pre-compile(*@repos is copy, :$save-to is copy) {
        my @results = eager gather for @repos -> $path {
            my $SPEC      := $*SPEC;
            temp $save-to  = $save-to ?? $SPEC.catdir($save-to, $path).IO !! $path.IO;
            say "==> Build directory: {$save-to.absolute}";
            my %meta     = %(from-json( $SPEC.catpath('', $path, 'META.info').IO.slurp) );
            my @provides = %meta<provides>.list;
            
            my @libs     = @provides.map({
                $*SPEC.rel2abs($SPEC.splitdir($_.value.IO.dirname).[0].IO, $path)
            }).unique.map({ CompUnitRepo::Local::File.new($_).Str });
            state @blibs.push($_) for @libs.map({ 
                CompUnitRepo::Local::File.new( $SPEC.rel2abs($SPEC.catdir('blib', $SPEC.abs2rel($_, $path)), $save-to) ).Str;
            });
            my $INC     := @blibs.unique, @libs, @*INC;

            my @files    = @provides.map({ $SPEC.rel2abs($_.value, $path).IO.path });
            my @deps     = extract-deps( @files );
            my @ordered  = build-dep-tree( @deps );

            my @compiled = @ordered.map({
                my $display-path = $SPEC.abs2rel($_.<path>, $path);
                print "[{$display-path}] {'.' x 42 - $display-path.chars} ";
                my $blib-file := $*SPEC.rel2abs($SPEC.catdir('blib', $SPEC.abs2rel($_.<path>, $path)).IO, $save-to).IO;
                my $out       := $*SPEC.rel2abs($SPEC.catpath('', $blib-file.dirname, "{$blib-file.basename}.{$*VM.precomp-ext}"), $save-to).IO;
                my $cu        := CompUnit.new( $_.<path> ) but role { # workaround for non-default :$out
                    has $!has-precomp;
                    has $!out;
                    submethod BUILD { 
                        $!out         := $out; 
                        $!has-precomp := ?$!out.f;
                    }
                    method precomp-path { $!out.absolute }
                }
                
                mkdirs($blib-file.dirname);
                mkdirs($cu.precomp-path.IO.dirname);
                
                say (my $result = $cu.precomp($out, :$INC, :force))
                    ?? "ok: {$SPEC.abs2rel($cu.precomp-path, $save-to)}" 
                    !! "FAILED";
                $cu;
            });

            # subclassing CompUnit seems to get screw when calling .new on a module 
            # that augments core functionality (Utils::PathTools and augment IO::Path?)
            # so we will use this structure for now instead of a custom CompUnit extension
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
