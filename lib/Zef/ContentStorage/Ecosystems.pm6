use Zef;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;


class Zef::ContentStorage::Ecosystems does ContentStorage {
    has $.name;
    has $.mirrors;
    has $.auto-update;
    has $.fetcher is rw;
    has $.cache is rw;

    has @!dists;

    method !gather-dists {
        once { self.update } if $.auto-update || !self!package-list-file.e;
        @!dists = +@!dists ?? @!dists !! eager gather for self!slurp-package-list -> $meta {
            if try { Zef::Distribution.new(|%($meta)) } -> $dist {
                take $dist;
            }
        }
    }

    method available {
        my $candidates := gather for self!gather-dists -> $dist {
            take Candidate.new(
                dist => $dist,
                uri  => ($dist.source-url || $dist.hash<support><source>),
                from => $?CLASS.^name ~ "<{$!name}>",
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
        die "Failed to update $!name" unless $!mirrors.first: -> $uri {
            my $save-as = $!cache.IO.child($uri.IO.basename);
            my $path    = try { $!fetcher.fetch($uri, $save-as) } || next;
            # this is kinda odd, but if $path is a file, then its fetching via http from p6c.org
            # and if its a directory its pulling from my ecosystems repo (this hides the difference for now)
            my $copy-from = $path.IO.d ?? $path.IO.child("{$!name}.json") !! $path;
            try {
                CATCH { default { warn $_ } }
                copy($copy-from, self!package-list-file)
            }
        }
        self!gather-dists;
    }

    # todo: handle %fields
    # todo: search for up to $max-results number of candidates for each *dist* (currently only 1 candidate per identity)
    method search(:$max-results = 5, *@identities, *%fields) {
        return () unless @identities || %fields;
        my @wanted = @identities;
        my %specs  = @wanted.map: { $_ => Zef::Distribution::DependencySpecification.new($_) }

        gather DIST: for self!gather-dists -> $dist {
            for @identities.grep(* ~~ any(@wanted)) -> $wants {
                last DIST unless +@wanted;
                if ?$dist.contains-spec( %specs{$wants} ) {
                    my $candidate = Candidate.new(
                        dist => $dist,
                        uri  => ($dist.source-url || $dist.hash<support><source>),
                        as   => $wants,
                        from => $?CLASS.^name ~ "<{$!name}>",
                    );
                    @wanted.splice(@wanted.first(/$wants/, :k), 1);
                    take $candidate;
                }
            }
        }
    }
}