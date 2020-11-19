use Zef;

# A 'Repository' that uses 1 or more other 'Repository' instances as backends. It abstracts the logic
# for e.g. sorting by version from multiple repositories. Each 'Repository' (including this one and
# whatever backends this may use) can be thought of as recommendation managers, where Zef::Repository
# gives a recommendation based on recommendations it gets from its backends (i.e. p6c, cpan, cached).

class Zef::Repository does Repository does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    # This is what is used to resolve dependencies.
    # Similar to .search(...), except it only returns 1 result (the best match) for each identity provided
    # i.e .search for Foo:ver<*> may return multiple versons, but .candidates would only ever return 1 even
    # if it exists in multiple repositories/backends.
    method candidates(Bool :$upgrade, *@identities ($, *@) --> Array[Candidate]) {
        # todo: have a `file` identity in Zef::Identity
        my @searchable = @identities.grep({ not $_.starts-with("." | "/") });

        # XXX: Delete this eventually
        my $dispatchers := $*PERL.compiler.version < v2018.08
            ?? self!plugins
            !! self!plugins.race(:batch(1)); # a new thread per Repository backend we will search with below

        # Search each Repository / backend
        my @unsorted-candis = $dispatchers.map: -> $storage {
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

        my Candidate @result = @distinct-requested-as;
        return @result;
    }

    # This is what is used to search for identities.
    # Similar to .candidates(...), except it will return more than one result per identity as appropriate.
    method search(:$max-results, Bool :$strict, *@identities ($, *@), *%fields --> Array[Candidate]) {
        return () unless @identities || %fields;

        # XXX: Delete this eventually
        my $dispatcher := $*PERL.compiler.version < v2018.08
            ?? self!plugins
            !! self!plugins.race(:batch(1)); # a new thread per Repository backend we will search with below

        my @unsorted-candis = $dispatcher.map: -> $storage {
            $storage.search(@identities, |%fields, :$max-results, :$strict).Slip
        }

        my Candidate @result = @unsorted-candis;
        return @result;
    }

    # Call 'store' on any Repository that provides that interface (by default just 'cached')
    method store(*@dists --> Nil) {
        for self!plugins.grep(*.^can('store')) -> $storage {
            $storage.?store(@dists);
        }
    }

    # Get all candidates/distributions from each backend
    method available(*@plugins --> Array[Candidate]) {
        my @can-available = self!plugins(@plugins).grep: -> $plugin {
            note "Plugin '{$plugin.short-name}' does not support `.available` -- Skipping" unless $plugin.can('available'); # UNDO doesn't work here yet
            $plugin.can('available');
        }

        my @available = @can-available.race(:batch(1)).map({ $_.available.Slip });

        my Candidate @results = @available;
        return @results;
    }

    # Update each Repository / backend (generally downloading a p6c.json or cpan.json file, or updating the 'cached' index)
    method update(*@plugins) {
        my @can-update = self!plugins(@plugins).grep: -> $plugin {
            note "Plugin '{$plugin.short-name}' does not support `.update` -- Skipping" unless $plugin.can('update'); # UNDO doesn't work here yet
            $plugin.can('update');
        }

        my %updates = @can-update.race(:batch(1)).map({ $_.update; $_.id => $_.available.elems }).hash;

        return %updates;
    }

    # Like self.plugins this returns a list of plugins that Pluggable + @.backends provides, but also allows
    # filtering which plugins are used by short-name (short-name is set in the config per Repository) so that
    # things like `--update=p6c` or `--/update=cpan` work.
    method !plugins(*@_) {
        +@_ ?? self.plugins.grep({.short-name ~~ any(@_)}) !! self.plugins
    }
}
