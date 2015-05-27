use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::PathTools;


# We cannot use this CompUnit until we figure out how to make it work with 
# MONKEY-TYPING modules that are currently loaded. In our case, Zef::Utils::PathTools 
# will return a CompUnit and not the Zef::CompUnit
class Zef::CompUnit is CompUnit {
    has $!path;
    has $!has-precomp;
    has $.precomp-path;
    has $.build-output is rw;

    method precomp($out, |c) {
        $!precomp-path = $out //= self.precomp-path // "{$!path}.{$*VM.precomp-ext}";
        mkdirs(self.precomp-path.IO.dirname);

        nextwith($!precomp-path, |c);
    }
}


class Zef::Builder does Zef::Phase::Building {
    # todo: lots of cleanup/refactoring
    method pre-compile(*@repos is copy, :$save-to is copy) {
        my @results = eager gather for @repos -> $path {
            my $SPEC := $*SPEC;

            # NOTE: this may change
            # Currently treats relative paths as relative to the current repo's path ($path).
            # It may or may not be better to treat them as relative to the users CWD. We shall see.
            temp $save-to = $save-to 
                ?? ($save-to.IO.is-absolute ?? $save-to.IO !! $SPEC.catdir($save-to, $path).IO) 
                !! $path.IO;

            say "===> Build directory: {$save-to.absolute}";
            my %meta     = %(from-json( $SPEC.catpath('', $path, 'META.info').IO.slurp) );
            my @provides = %meta<provides>.list;
            my @libs     = @provides.map({
                $*SPEC.rel2abs($SPEC.splitdir($_.value.IO.dirname).[0].IO // $SPEC.curdir, $path)
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
                my $blib-file := $SPEC.rel2abs($SPEC.catdir('blib', $SPEC.abs2rel($_.<path>, $path)).IO, $save-to).IO;
                my $out       := $SPEC.rel2abs($SPEC.catpath('', $blib-file.dirname, "{$blib-file.basename}.{$*VM.precomp-ext}"), $save-to).IO;
                my $cu        := CompUnit.new( $_.<path> ) but role { # workaround for non-default :$out
                    has $!has-precomp;
                    has $!out;
                    has $.build-output is rw;
                    submethod BUILD { 
                        $!out         := $out; 
                        $!has-precomp := ?$!out.f;
                    }
                    method precomp-path { $!out.absolute }
                }
                
                mkdirs($blib-file.dirname);
                mkdirs($cu.precomp-path.IO.dirname);

                print $cu.build-output  = "[{$display-path}] {'.' x 42 - $display-path.chars} ";
                my $output-result       = ($cu.precomp($out, :$INC, :force)
                    ?? "ok: {$SPEC.abs2rel($cu.precomp-path, $save-to)}\n"
                    !! "FAILED\n");
                print $output-result;
                $cu.build-output ~= $output-result;

                $cu;
            });

            # subclassing CompUnit seems to get screw when calling .new on a module 
            # that augments core functionality (Utils::PathTools and augment IO::Path?)
            # so we will use this structure for now instead of a custom CompUnit extension
            take {  
                ok           => ?(@compiled.grep({ ?$_.has-precomp }).elems == @provides.elems),
                precomp-path => @blibs[0], 
                path         => $path, 
                curlfs       => @compiled, 
                sources      => @provides,
                module       => %meta<name>,
            }
        }

        return @results;
    }
}
