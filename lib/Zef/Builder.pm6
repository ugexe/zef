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


# Provide functionality for precompiling modules
class Zef::Builder {
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
            my @libs     = %meta<provides>.list.map({
                $*SPEC.rel2abs($SPEC.splitdir($_.value.IO.dirname).[0].IO // $SPEC.curdir, $path)
            }).unique.map({ CompUnitRepo::Local::File.new($_).Str });
            state @blibs.push($_) for @libs.map({ 
                CompUnitRepo::Local::File.new( $SPEC.rel2abs($SPEC.catdir('blib', $SPEC.abs2rel($_, $path)), $save-to) ).Str;
            });
            my $INC     := @blibs.unique, @libs, @*INC;
            my @files    = %meta<provides>.list.map({ $SPEC.rel2abs($_.value, $path).IO.path });

            # Build the @dep chain for the %META.<provides> by parsing the source
            my @provides-as-deps = gather for @(extract-deps( @files ).list) -> $info is rw {
                $info.<depends> = [$info.<depends>.list.map({ %meta.<provides>.{$_} })];
                $info.<name>    = %meta.<provides>.list.grep({ my $f = $_.value; $info.<path> ~~ /$f$/ }).[0].value;
                take $info;
            }

            # @deps is a partial META.info hash, so pass the provides
            my @levels   = Zef::Utils::Depends.new(projects => @provides-as-deps).topological-sort;
            my @compiled = eager gather for @levels -> $level {
                # $module-key may be a module name (Zef::Builder) or a file path (/lib/Zef/Builder.pm6)
                # For provides we use file paths as some module names (provides key) may share a path (provides value)
                for $level.list -> $module-key {
                    my $display-path = $module-key;
                    my $full-path   := $*SPEC.rel2abs($module-key, $path);
                    my $blib-file := $SPEC.rel2abs($SPEC.catdir('blib', $module-key).IO, $save-to).IO;
                    my $out       := $SPEC.rel2abs($SPEC.catpath('', $blib-file.dirname, "{$blib-file.basename}.{$*VM.precomp-ext}"), $save-to).IO;
                    my $cu        := CompUnit.new( $*SPEC.rel2abs($module-key, $path) ) but role { 
                        # workaround for non-default :$out path (use /blib/lib instead of /lib)
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

                    $cu.build-output  = "[{$display-path}] {'.' x 42 - $display-path.chars} ";
                    $cu.build-output ~= ($cu.precomp($out, :$INC, :force)
                        ?? "ok: {$SPEC.abs2rel($cu.precomp-path, $save-to)}\n"
                        !! "FAILED\n");

                    print $cu.build-output;

                    take $cu;
                }
            }

            # subclassing CompUnit seems to get screw when calling .new on a module 
            # that augments core functionality (Utils::PathTools and augment IO::Path?)
            # so we will use this structure for now instead of a custom CompUnit extension
            take {  
                ok           => ?(@compiled.grep({ ?$_.has-precomp }).elems == %meta<provides>.list.elems),
                precomp-path => @blibs[0], 
                path         => $path, 
                curlfs       => @compiled, 
                sources      => %meta<provides>.list,
                module       => %meta<name>,
            }
        }

        return @results;
    }
}
