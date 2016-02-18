use Zef;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

class Zef::ContentStorage::P6C does ContentStorage {
    has $.mirrors;
    has $.auto-update;
    has $.fetcher is rw;
    has $.cache is rw;

    has @!dists;

    method !gather-dists {
        once { self.update } if $.auto-update || !self!package-list-file.e;
        return @!dists if +@!dists;

        @!dists = gather for self!slurp-package-list -> $meta {
            my $dist = Zef::Distribution.new(|%($meta));
            take $dist;
        }
    }

    method available {
        my $candidates := gather for self!gather-dists -> $dist {
            take Candidate.new(
                dist => $dist,
                uri  => ($dist.source-url || $dist.hash<support><source>),
                from => $?CLASS.^name,
            );
        }
    }

    method IO {
        my $dir = $!cache.IO.child('p6c').IO;
        $dir.mkdir unless $dir.e;
        $dir;
    }

    method !package-list-file  { $ = self.IO.child('packages.json') }
    method !slurp-package-list { @ = |from-json(self!package-list-file.slurp) }

    method update {
        die "Failed to update p6c" unless $!mirrors.first: -> $uri {
            my $save-as = $!cache.IO.child($uri.IO.basename);
            my $path    = try { $!fetcher.fetch($uri, $save-as) } || next;
            # this is kinda odd, but if $path is a file, then its fetching via http from p6c.org
            # and if its a directory its pulling from my ecosystems repo (this hides the difference for now)
            $path = $path.IO.child('p6c.json') if $path.IO.d;
            try { copy($path, self!package-list-file) } || next;
        }
        @!dists = self!slurp-package-list.map({ Zef::Distribution.new(|%($_)) })
    }

    # todo: handle %fields
    # todo: search for up to $max-results number of candidates for each *dist* (currently only 1 candidate per identity)
    method search(:$max-results = 5, *@identities, *%fields) {
        return () unless @identities || %fields;
        my @wanted = @identities;
        my %specs  = @wanted.map: { $_ => Zef::Distribution::DependencySpecification.new($_) }

        cache gather DIST: for self!gather-dists -> $dist {
            for @identities.grep(* ~~ any(@wanted)) -> $wants {
                if ?$dist.contains-spec( %specs{$wants} ) {
                    my $candidate = Candidate.new(
                        dist => $dist,
                        uri  => ($dist.source-url || $dist.hash<support><source>),
                        as   => $wants,
                        from => $?CLASS.^name,
                    );
                    take $candidate;
                    @wanted.splice(@wanted.first(/$wants/, :k), 1);
                    last DIST unless +@wanted;
                }
            }
        }
    }
}