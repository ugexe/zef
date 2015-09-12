use Zef::Utils::PathTools;
use Zef::Utils::Depends;


role Zef::Roles::Precompiling {
    my $DEFAULT-TARGET = $*VM.precomp-target;

    method precomp-cmds(:@targets = [$DEFAULT-TARGET]) {
        my %provides-abspaths := $.provides(:absolute).hash;

        # Build the @dep chain for the %meta<provides> by parsing the 
        # use/require/need from the module source. todo: speed up.
        my @deps := extract-deps( %provides-abspaths.values ).cache;

        my $provides-as-deps := gather for @deps -> $dep-meta is rw {
            $dep-meta.<depends> = [%provides-abspaths.{$dep-meta.<depends>.cache}];
            $dep-meta.<name>    = %provides-abspaths.values\
                .first: { $_.IO.ACCEPTS($dep-meta.<path>.IO.absolute($.path)) }
            take $dep-meta;
        }


        # @provides-as-deps is a partial META.info hash, so pass the $meta.<provides>
        # Note topological-sort with no arguments will sort the class's @projects (provides in this case)
        my @levels := Zef::Utils::Depends.new(projects => $provides-as-deps.cache).topological-sort;

        # Create the build order for the `provides`
        @levels.map: -> $level {
            my $bb = gather for $level.cache -> $module-id {
                my $file := $module-id.IO.absolute($.path).IO;

                # Many tests are written with the assumption the cwd is their projects base directory.
                my $file-rel := ?$file.IO.is-relative ?? $file.IO !! $file.IO.relative($.path);

                for @targets -> $target {
                    my $out-rel = $.to-precomp($file, :!absolute, :$target);
                    my $out-abs = $.to-precomp($file, :absolute,  :$target);

                    mkdirs($out-abs.IO.dirname) unless $out-abs.IO.dirname.IO.e;

                    take $($*EXECUTABLE, $.i-paths.cache, "--target={$target}", "--output={$out-rel}", $file-rel)
                }
            }
            $bb;
        }
    }

    method to-precomp(IO::Path $file, Bool :$absolute, :$target = $DEFAULT-TARGET) {
        my $file-rel    := ?$file.IO.is-relative ?? $file.IO !! $file.IO.relative($.path);
        my $precomp-rel := $.precomp-path.child(
            $file-rel.IO.relative( $.source-path.IO.relative($.path) )
        ).IO.relative($.path) ~ ".{$target ~~ /mbc/ ?? 'moarvm' !! 'jar'}";

        return $absolute
            ?? $precomp-rel.IO.absolute($.path).IO
            !! $precomp-rel.IO;
    }

    method provides-precomp(Bool :$absolute, :$target = $DEFAULT-TARGET) {
        # todo: $.path.child($^b)?
        $.provides.hash.kv.map({ $^a => $.to-precomp($^b.IO, :$absolute, :$target) }).hash;
    }
}
