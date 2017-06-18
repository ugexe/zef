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
    has $.mirrors;
    has $.auto-update;

    has $.cache is rw;
    has @!dists;

    method IO(--> IO::Path) { my $dir = $!cache.IO; $dir.mkdir unless $dir.e; $dir }

    method available(--> Seq) {
        self!gather-dists.map: -> $dist {
            Candidate.new(
                dist => $dist,
                uri  => ($dist.source-url || $dist.hash<support><source>),
                from => self.id,
                as   => $dist.identity,
            );
        }
    }

    # Rebuild the manifest/index by recursively searching for META files
    method update(--> Bool) {
        LEAVE { self.store(|@!dists) }

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

        my $content = join "\n", %dcache.map: { join "\0", (.key, .value) }
        so $content ?? self!spurt-package-list($content) !! False;
    }

    # todo: handle %fields
    # note this doesn't apply the $max-results per identity searched, and always returns a 1 dist
    # max for a single identity (todo: update to handle $max-results for each @identities)
    method search(:$max-results = 5, Bool :$strict, *@identities, *%fields --> Seq) {
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
    method store(*@new --> Bool) {
        my %lookup andthen do given self!package-list-path.open(:r) {
            LEAVE {.close}
            .lock: :shared;
            for .lines -> $line {
                my ($id, $path) = $line.split("\0");
                %lookup{$id} = $path;
            }
        }

        do given self!package-list-path.open(:w) {
            %lookup{$_.identity} = $_.IO.absolute for |@new;
            my $content = join "\n", %lookup.map: { join "\0", (.key, .value) }
            self!spurt-package-list($content) if $content;
            return True;
        }

        return False;
    }

    method !package-list-path(--> IO::Path)  {
        my $path = self.IO.child('MANIFEST.zef');
        $path.spurt('') unless $path.e;
        $path;
    }

    method !slurp-package-list(--> List) {
        return [ ] unless self!package-list-path.e;

        do given self!package-list-path.open(:r) {
            LEAVE {.close}
            .lock: :shared;
            .slurp.lines.map({.split("\0")[1]}).cache;
        }
    }

    method !spurt-package-list($content --> Bool) {
        do given self!package-list-path.open(:w) {
            LEAVE {.close}
            .lock;
            try .spurt($content);
        }
    }

    # Abstraction to handle automatic updating of package list and/or local index
    method !gather-dists(--> List) {
        once { self.update } if $.auto-update || !self!package-list-path.e;
        return @!dists if +@!dists;

        @!dists = gather for self!slurp-package-list.grep(*.IO.e) -> $path {
            take($_) with try Zef::Distribution::Local.new($path);
        }
    }
}
