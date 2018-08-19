use Zef;

class Zef::Repository does Pluggable {
    method candidates(Bool :$upgrade, *@identities ($, *@)) {
        # todo: have a `file` identity in Zef::Identity
        my @searchable = @identities.grep({ not $_.starts-with("." | "/") });

        my $unsorted-candis := self.plugins.map: -> $storage {
            # todo: (cont. from above): Each Repository should just filter this themselves
            my @search-for = $storage.id eq 'Zef::Repository::LocalCache' ?? @identities !! @searchable;
            $storage.search(@search-for, :strict).Slip
        }

        my $unsorted-grouped-candis := $unsorted-candis.categorize({.dist.name}).values;

        # Take the distribution with the highest version out of all matching distributions from all repositories
        my $sorted-candis := $unsorted-grouped-candis.map: -> $candis {
            my @presorted = $candis.sort(*.dist.ver);
            my $version   = @presorted.tail.dist.ver;

            # Prefer candidates from Zef::Repository::Local to avoid redownloading cached items
            my @sorted = @presorted.grep({ .dist.ver eq $version }).sort({ $^a.from eq 'Zef::Repository::LocalCache' });
            @sorted.tail;
        }

        # $candi.as tells us what string was used to request its distribution ($candi.dist)
        # So this is similar to the .categorize(*.dist.name) filter above, except it
        # covers when two different repositories have a matching candidate with different
        # distribution names (likely matching *module* names in provides)
        my @distinct-requested-as = $sorted-candis.unique(:as(*.as));
    }

    method search(:$max-results = 5, Bool :$strict, *@identities ($, *@), *%fields) {
        return () unless @identities || %fields;

        self.plugins.map: -> $storage {
            $storage.search(@identities, |%fields, :$max-results, :$strict).Slip
        }
    }

    method store(*@dists) {
        for self.plugins.grep(*.^can('store')) -> $storage {
            $storage.?store(@dists);
        }
    }

    method available(*@from) {
        my %dists;
        my $check-plugins := +@from ?? self.plugins.grep({.short-name ~~ any(@from)}) !! self.plugins;
        my $candis := gather for $check-plugins.grep(*.^can('available')) -> $storage {
            take $_ for |$storage.available;
        }
    }

    method update(*@names) {
        eager gather for self.plugins(@names) -> $plugin {
            next() R, warn "Plugin {$plugin.short-name} doesn't support `.update`"\
                if +@names && !$plugin.can('update'); # `.update` is an optional interface requirement
            take $plugin.id => $plugin.update.elems;
        }
    }
}
