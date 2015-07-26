use Zef::Utils::PathTools;
use Zef::Utils::Depends;

role Zef::Roles::Precompiling {
    my $DEFAULT-TARGET = $*VM.precomp-ext ~~ /moar/ ?? 'mbc' !! 'jar';

    method precomp-cmds(:@targets = [$DEFAULT-TARGET]) {
        my @provides-abspaths = %.meta<provides>.values>>.IO>>.absolute($.path);

        # Build the @dep chain for the %meta<provides> by parsing the 
        # use/require/need from the module source. todo: speed up.
        my @deps = extract-deps( @provides-abspaths ).list;
        my @provides-as-deps = eager gather for @deps -> $dep-meta is rw {
            $dep-meta.<depends> = [$dep-meta.<depends>.list.map(-> $name { 
                %.meta.<provides>.list\
                    .first({ $_.key eq $name })\
                    .map({ $_.value.IO.absolute($.path) });
            } )];

            $dep-meta.<name> = %.meta.<provides>.list\
                .map({ $_.value.IO.absolute($.path).IO })\
                .first({ $_.IO.ACCEPTS($dep-meta.<path>.IO.absolute($.path)) });

            take $dep-meta;
        }

        my @i-paths= ($.precomp-path, $.source-path, @.includes)\
            .grep(*)\
            .map({ $_.IO.is-relative ?? $_.IO.relative !! $_.IO.relative($.path) })\
            .map({ qqw/-I$_/ });
        # @provides-as-deps is a partial META.info hash, so pass the $meta.<provides>
        # Note topological-sort with no arguments will sort the class's @projects (provides in this case)
        my @levels = Zef::Utils::Depends.new(projects => @provides-as-deps).topological-sort;

        # Create the build order for the `provides`
        my @cmds = @levels.map: -> $level {
            my $build-level = eager gather for $level.list -> $module-id {
                my $file = $module-id.IO.absolute($.path).IO;
                # Many tests are written with the assumption the cwd is their projects base directory.
                my $file-rel = ?$file.IO.is-relative ?? $file.IO !! $file.IO.relative($.path);

                for @targets -> $target {
                    my $out-rel = $.to-precomp($file, :!absolute, :$target);
                    my $out-abs = $.to-precomp($file, :absolute,  :$target);

                    mkdirs($out-abs.IO.dirname) unless $out-abs.IO.dirname.IO.e;

                    take [$*EXECUTABLE, @i-paths, "--target={$target}", "--output={$out-rel}", $file-rel]
                }
            }
        }

        return @cmds;
    }

    method to-precomp(IO::Path $file, Bool :$absolute, :$target = $DEFAULT-TARGET) {
        my $file-rel = ?$file.IO.is-relative ?? $file.IO !! $file.IO.relative($.path);
        say "FILE REL: {$file-rel.perl}";
        my $precomp-rel = $.precomp-path.child($file-rel.IO.relative($.source-path)).IO.relative($.path)
            ~ ".{$target ~~ /mbc/ ?? 'moarvm' !! 'jar'}";

        return $absolute 
            ?? $precomp-rel.IO.absolute($.path)
            !! $precomp-rel;
    }

    multi method provides(Bool :$absolute, :$target = $DEFAULT-TARGET, Bool :$precomp) {
        nextwith(:$absolute) unless $precomp;
        $.provides.hash.kv.map({ $^a => $.to-precomp($^b.IO, :$absolute, :$target) }).hash;
    }

}