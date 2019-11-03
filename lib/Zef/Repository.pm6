use Zef;

class Zef::Repository does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    method candidates(Bool :$upgrade, *@identities ($, *@)) {
        # todo: have a `file` identity in Zef::Identity
        my @searchable = @identities.grep({ not $_.starts-with("." | "/") });

        # XXX: Delete this eventually
        my $dispatchers := $*PERL.compiler.version < v2018.08
            ?? self!plugins
            !! self!plugins.race(:batch(1));

        my @unsorted-candis = $dispatchers.map: -> $storage {
            # todo: (cont. from above): Each Repository should just filter this themselves
            my @search-for = $storage.id eq 'Zef::Repository::LocalCache' ?? @identities !! @searchable;
            $storage.search(@search-for, :strict).Slip
        }

        my @unsorted-grouped-candis = @unsorted-candis.categorize({.dist.meta<name>}).values;

        # Take the distribution with the highest version out of all matching distributions from each repository
        my @partially-sorted-candis = @unsorted-grouped-candis.map: -> $candis {
            my @presorted = $candis.sort(*.dist.api).sort(*.dist.ver);
            my $api       = @presorted.tail.dist.api;
            my $version   = @presorted.tail.dist.ver;

            # Prefer candidates from Zef::Repository::Local to avoid redownloading cached items
            my @sorted = @presorted.grep({ .dist.api eq $api }).grep({ .dist.ver eq $version }).sort({ $^a.from eq 'Zef::Repository::LocalCache' });
            @sorted.tail;
        }

        # Sort the highest distribution versions from each repository. This must be done
        # before the call to `.unique` later so that unique doesn't remove the higher
        # versioned distribution based on randomness of @unsorted-candis.categorize({.dist.name}).values
        my @sorted-candis = @partially-sorted-candis.sort(*.dist.ver).sort(*.dist.api).reverse;

        # $candi.as tells us what string was used to request its distribution ($candi.dist)
        # So this is similar to the .categorize(*.dist.name) filter above, except it
        # covers when two different repositories have a matching candidate with different
        # distribution names (likely matching *module* names in provides)
        my @distinct-requested-as = @sorted-candis.unique(:as(*.as));
        return @distinct-requested-as;
    }

    method search(:$max-results = 5, Bool :$strict, *@identities ($, *@), *%fields) {
        return () unless @identities || %fields;

        # XXX: Delete this eventually
        my $dispatcher := $*PERL.compiler.version < v2018.08
            ?? self!plugins
            !! self!plugins.race(:batch(1));

        my @unsorted-candis = $dispatcher.map: -> $storage {
            $storage.search(@identities, |%fields, :$max-results, :$strict).Slip
        }

        return @unsorted-candis;
    }

    method store(*@dists) {
        for self!plugins.grep(*.^can('store')) -> $storage {
            $storage.?store(@dists);
        }
    }

    method available(*@plugins) {
        my @can-available = self!plugins(@plugins).grep: -> $plugin {
            note "Plugin '{$plugin.short-name}' does not support `.available` -- Skipping" unless $plugin.can('available'); # UNDO doesn't work here yet
            $plugin.can('available');
        }

        my @available = @can-available.race(:batch(1)).map({ $_.available.Slip });

        return @available;
    }

    method update(*@plugins) {
        my @can-update = self!plugins(@plugins).grep: -> $plugin {
            note "Plugin '{$plugin.short-name}' does not support `.update` -- Skipping" unless $plugin.can('update'); # UNDO doesn't work here yet
            $plugin.can('update');
        }

        my %updates = @can-update.race(:batch(1)).map({ $_.id => $_.update.elems }).hash;

        return %updates;
    }

    method !plugins(*@_) {
        +@_ ?? self.plugins.grep({.short-name ~~ any(@_)}) !! self.plugins
    }
}
