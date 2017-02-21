use Zef;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

my %dist_cache;

class Zef::Repository::Ecosystems does Repository {
    has $.name;
    has $.mirrors;
    has $.auto-update;
    has $.fetcher is rw;
    has $.cache is rw;

    has $.update-counter;

    method id { $?CLASS.^name.split('+', 2)[0] ~ "<{$!name}>" }

    method !dists {
        # Only update once, and only update automatically if $!auto-update is enabled or no package list exists yet
        self.update if ($!auto-update && !$!update-counter)
                    or !self!package-list-file.e;

        %dist_cache{self.id} := %dist_cache{self.id}
            ?? %dist_cache{self.id}
            !! cache gather for self!slurp-package-list -> $meta {
                take($_) with try Zef::Distribution.new(|%($meta));
            }
    }

    method available {
        my $candidates := gather for self!dists -> $dist {
            take Candidate.new(
                dist => $dist,
                uri  => ($dist.source-url || $dist.hash<support><source>),
                from => self.id,
                as   => $dist.identity,
            );
        }
    }

    method IO {
        my $dir = $!cache.IO.child($!name).IO;
        $dir.mkdir unless $dir.e;
        $dir;
    }

    method !package-list-file  {
        $ = self.IO.child('packages.json')
    }

    method !slurp-package-list {
        self!package-list-file.e
            ?? |from-json(self!package-list-file.slurp)
            !! [ ];
    }

    method update {
        $!update-counter++;
        die "Failed to update $!name" unless $!mirrors.first: -> $uri {
            my $save-as = $!cache.IO.child($uri.IO.basename);
            my $path    = try { $!fetcher.fetch($uri, $save-as) } || next;
            # this is kinda odd, but if $path is a file, then its fetching via http from p6c.org
            # and if its a directory its pulling from my ecosystems repo (this hides the difference for now)
            my $copy-from = $path.IO.d ?? $path.IO.child("{$!name}.json") !! $path;
            try {
                CATCH { default { warn $_ } }
                copy($copy-from, self!package-list-file);
            }
        }
        %dist_cache{self.id}:delete;
        self!dists;
    }

    # todo: handle %fields
    # todo: search for up to $max-results number of candidates for each *dist* (currently only 1 candidate per identity)
    method search(:$max-results = 5, Bool :$strict, *@identities, *%fields) {
        return () unless @identities || %fields;
        my @wanted = @identities;
        my %specs  = @wanted.map: { $_ => Zef::Distribution::DependencySpecification.new($_) }

        gather DIST: for self!dists -> $dist {
            for @identities.grep(* ~~ any(@wanted)) -> $wants {
                if ?$dist.contains-spec( %specs{$wants}, :$strict ) {
                    my $candidate = Candidate.new(
                        dist => $dist,
                        uri  => ($dist.source-url || $dist.hash<support><source>),
                        as   => $wants,
                        from => self.id,
                    );
                    take $candidate;

                    # XXX: see notes in Zef::Repository::LocalCache::search
                    #@wanted.splice(@wanted.first(/$wants/, :k), 1);
                    #last RDIST unless +@wanted;
                }
            }
        }
    }
}