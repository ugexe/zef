use Zef::Authority;
use Zef::Utils::Depends;

# XXX Authority:: modules will be getting replaced with Storage (or Storage related modules)

my @skip = <v6 MONKEY-TYPING MONKEY_TYPING strict fatal nqp NativeCall cur lib Test>;

class Zef::Authority::Local does Zef::Authority {
    method update-projects(*@wants is copy) {
        my @files = gather for @wants -> $path {
            next unless $path.IO.e;
            given $path {
                when $_.ends-with('META6.json')  && $_.IO.e {
                    take ~$_;
                }
                when $_.ends-with('META.info') && $_.IO.e {
                    take ~$_;
                }
                when $_.IO.child('META6.json').IO.e {
                    take ~$_.IO.child('META6.json');
                }
                when $_.IO.child('META.info').IO.e {
                    take ~$_.IO.child('META.info');
                }
            }
        }
        my @metas = gather for @files.grep(*.so) -> $file {
            next unless $file.IO.f;
            my $m = try { from-json($file.IO.slurp) } or next;
            $m<source-type> = 'local';
            $m<source-path> = $file.IO.absolute;
            take $m;
        }

        # this wont hold up to multiple calls. needs a better solution
        state @combined-projects = |@!projects, |@metas;
        @!projects = @combined-projects;
    }

    # needs to be redone to register by source-type and handle projects.json file specifically.
    # just hacked together to quickly allow local installs
    method get(
        Zef::Authority::Local:D: 
        *@wants, # really paths
        :@ignore,
        :$save-to is copy, # todo: copy files to $save-to if defined
        Bool :$depends,
        Bool :$test-depends,
        Bool :$build-depends,
        Bool :$fetch = True,
    ) {
        self.update-projects(@wants) if $fetch && !@!projects.elems;
        my @wants-dists = self.update-projects(@wants).cache;

        my @wants-dists-filtered = !@ignore ?? @wants-dists !! @wants-dists.grep({
               (!$depends       || any($_.<depends>.cache.grep(*.so))       ~~ none(@ignore.grep(*.so)))
            && (!$test-depends  || any($_.<build-depends>.cache.grep(*.so)) ~~ none(@ignore.grep(*.so)))
            && (!$build-depends || any($_.<test-depends>.cache.grep(*.so))  ~~ none(@ignore.grep(*.so)))
        });

        return () unless @wants-dists-filtered;

        # Determine the distribution dependencies we want/need
        my $levels = ?$depends
            ?? Zef::Utils::Depends.new(:projects(@wants-dists)).topological-sort( @wants-dists-filtered, 
                :$depends, :$build-depends, :$test-depends)
            !! @wants-dists-filtered.map({ $_.hash.<name> });

        # Try to fetch each distribution dependency
        eager gather for $levels.cache -> $level {
            for $level.cache -> $package-name {
                next if $package-name.lc ~~ any(@skip>>.lc);
                # todo: filter projects by version/auth
                my %dist = @!projects.cache.first({ $_.<name>.lc eq $package-name.lc }).hash;
                die "!!!> No source-path for $package-name (META info lost?)" and next unless ?%dist<source-path>;

                # todo: implement the rest of however github.com transliterates paths
                my $path       = %dist<source-path>.IO.parent;
                my $basename   = %dist<name>.trans(':' => '-');
                # temp $save-to  = ~$save-to.IO.child($basename);
                # cp $path, $save-to
                temp $save-to  = $path;
                take { :unit-id(%dist<name>), :$path, :ok(?$save-to.IO.e) }
            }
        }
    }
}
