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
            my $path    = $!fetcher.fetch($uri, $save-as);
            if $path.IO.d {
                $path = $path.IO.child('p6c.json');
            }
            try { copy($path, self!package-list-file) } || next;
        }
        @!dists = self!slurp-package-list.map({ Zef::Distribution.new(|%($_)) })
    }

    # todo: handle %fields
    method search(:$max-results = 5, *@identities, *%fields) {
        return () unless @identities || %fields;
        my @wanted = @identities;
        cache gather DIST: for self!gather-dists -> $dist {
            for @identities.grep(* ~~ any(@wanted)) -> $wants {
                my $spec = Zef::Distribution::DependencySpecification.new($wants);
                if ?$dist.contains-spec($spec) {
                    $dist.metainfo<requested-as> = $wants;
                    take $dist;
                    @wanted.splice(@wanted.first(/$wants/, :k), 1);
                    last DIST unless +@wanted;
                }
            }
        }
    }
}