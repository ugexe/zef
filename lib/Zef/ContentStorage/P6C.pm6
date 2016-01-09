use Zef;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

class Zef::ContentStorage::P6C does ContentStorage {
    has $.mirrors;
    has $.auto-update;
    has $.fetcher is rw;
    has $.cache is rw;

    method IO {
        my $dir = $!cache.IO.child('p6c').IO;
        $dir.mkdir unless $dir.e;
        $dir;
    }
    method package-list-file { $ = self.IO.child('packages.json').IO }
    method !slurp-package-list { @ = |from-json(self.package-list-file.slurp) }

    method update {
        die "Failed to update p6c" unless $!mirrors.first: -> $uri {
            my $save-as = $!cache.IO.child($uri.IO.basename);
            my $path    = $!fetcher.fetch($uri, $save-as);
            if $path.IO.d {
                $path = $path.IO.child('p6c.json');
            }
            try { copy($path, self.package-list-file) } || next;
            so self.package-list-file.e;
        }
    }

    # todo: handle %fields
    method search(:$max-results = 5, *@identities, *%fields) {
        self.update if $.auto-update || !self.package-list-file.e;
        state @dists = self!slurp-package-list.map({ Zef::Distribution.new(|%($_)) });
        return () unless @identities || %fields;

        my @matches  = eager gather for @identities -> $wanted {
            my $spec = Zef::Distribution::DependencySpecification.new($wanted);
            for @dists -> $dist {
                take $dist if ?$dist.contains-spec($spec);
            }
        }
    }
}