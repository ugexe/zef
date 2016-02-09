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

    method available { self!gather-dists }

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
                        dist           => $dist,
                        uri            => $dist.source-url,
                        requested-as   => $wants,
                        recommended-by => self.^name,
                    );
                    take $candidate;
                    @wanted.splice(@wanted.first(/$wants/, :k), 1);
                    last DIST unless +@wanted;
                }
            }
        }
    }
}