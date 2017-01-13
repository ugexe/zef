use Zef;
use Zef::Distribution::Local;
use Zef::Distribution::DependencySpecification;

# Intended to:
# 1) Keep track of contents of a directory using a manifest.
#   a) full update to recursively search location to discover everything
#   b) .store method to be called after something is fetched, allowing
#       the single entry to be added to the manifest without having to search
# 2) If a requested identity matches anything found in the manifest already
#    then it will return *that* instead of necessarily making net requests
#    for other Repository like p6c or CPAN (although such choices are
#    made inside Zef::Repository itself)
class Zef::Repository::LocalCache does Repository {
    state $lock = Lock.new;
    has $.mirrors;
    has $.auto-update;
    has $.cache is rw;

    has @!dists;

    # Abstraction to handle automatic updating of package list and/or local index
    method !gather-dists {
        once { self.update } if $.auto-update || !self!manifest-file.e;
        return @!dists if +@!dists;

        @!dists = gather for self!slurp-manifest.lines -> $entry {
            my ($identity, $path) = $entry.split("\0");
            next unless "{$path}".IO.e;
            if try { Zef::Distribution::Local.new($path) } -> $dist {
                take $dist;
            }
        }
    }

    method !manifest-file  {
        my $path = self.IO.child('MANIFEST.zef');
        $path.spurt('') unless $path.e;
        $path;
    }

    method !slurp-manifest { $ = self!manifest-file.IO.slurp }

    method available {
        my $candidates := gather for self!gather-dists -> $dist {
            take Candidate.new(
                dist => $dist,
                uri  => ($dist.source-url || $dist.hash<support><source>),
                from => self.id,
                as   => $dist.identity,
            );
        }
    }

    method IO {
        my $dir = $!cache.IO;
        $dir.mkdir unless $dir.e;
        $dir;
    }

    # Rebuild the manifest/index by recursively searching for META files
    method update {
        my @stack = $!cache;
        my %dcache;

        while ( @stack ) {
            my $current = @stack.pop.IO;
            next if !$current.e
                ||  $current.f
                ||  $current.basename.starts-with('.')
                ||  %dcache.values.grep({ $current.absolute.starts-with($_.IO.absolute) });

            my $dist = try Zef::Distribution::Local.new($current);

            unless ?$dist {
                @stack.append($current.dir.grep(*.d)>>.absolute);
                next;
            }

            %dcache{$dist.identity} //= $dist;
        }

        @!dists = %dcache.values;
        self!update;
    }

    method !update(*@dists) {
        self.store(|@!dists);
        @!dists;
    }

    # todo: handle %fields
    # note this doesn't apply the $max-results per identity searched, and always returns a 1 dist
    # max for a single identity (todo: update to handle $max-results for each @identities)
    method search(:$max-results = 5, Bool :$strict, *@identities, *%fields) {
        return () unless @identities || %fields;
        my @wanted = |@identities;
        my %specs  = @wanted.map: { $_ => Zef::Distribution::DependencySpecification.new($_) }

        # identities that are cached in the localcache manifest
        gather RDIST: for |self!gather-dists -> $dist {
            for @identities.grep(* ~~ any(@wanted)) -> $wants {
                if ?$dist.contains-spec( %specs{$wants}, :$strict ) {
                    my $candidate = Candidate.new(
                        dist => $dist,
                        uri  => $dist.IO.absolute,
                        as   => $wants,
                        from => self.id,
                    );
                    take $candidate;

                    # These are a short circuit that can be used again if the manifest format
                    # is changed such that its saved in order from highest version to lowest version
                    #@wanted.splice(@wanted.first(/$wants/, :k), 1);
                    #last RDIST unless +@wanted;
                }
            }
        }
    }

    # After the `fetch` phase an app can call `.store` on any Repository that
    # provides it, allowing each Repository to do things like keep a simple list of
    # identities installed, keep a cache of anything installed (how its used here), etc
    method store(*@new) {
        $lock.protect({
            # xxx: terribly inefficient
            my %lookup;
            for self!slurp-manifest.lines -> $line {
                my ($id, $path) = $line.split("\0");
                %lookup{$id} = $path;
            }
            %lookup{$_.identity} = $_.IO.absolute for |@new;
            my $contents = join "\n", %lookup.map: { join "\0", (.key, .value) }
            self!manifest-file.spurt($contents ~ "\n") if $contents;
        })
    }
}
