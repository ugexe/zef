use Zef;

class Zef::Repository does PackageRepository does Pluggable {

    =begin pod

    =title class Zef::Repository

    =subtitle A configurable implementation of the Repository interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef::Fetch;
        use Zef::Repository;

        # Need a fetcher and cache for the backend repository to fetch and save to 
        my @fetching_backends = [
            { module => "Zef::Service::Shell::curl" },
            { module => "Zef::Service::Shell::PowerShell::download" },
        ];
        my $fetcher = Zef::Fetch.new(:backends(@fetching_backends));
        my $cache   = $*TMPDIR.child("{time}") andthen { mkdir $_ unless $_.IO.e };

        # Create repo using a backend that is essentially just: Zef::Repository::Ecosystems.new(|%options-shown-below)
        # Note usually options are all Str so they can be set in the config file, but for the time being the cache
        # and fetcher objects need to be passed in here as well (currently auto-magically done in Zef::Client but could
        # be done in Zef::Repository)
        my $repo = Zef::Repository.new(
            backends => [
                {
                    module     => "Zef::Repository::Ecosystems",
                    options => {
                        cache       => $cache,
                        fetcher     => $fetcher,
                        name        => "cpan",
                        auto-update => 1,
                        mirrors     => ["https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/11efd9077b398df3766eaa7cf8e6a9519f63c272/cpan.json"]
                    }
                },
            ],
        );

        # Print out all available distributions from all supplied backend repositories
        say $_.dist.identity for $repo.available;

        # Get the best match for 'Zef'
        my @matches = $repo.candidates("Zef");
        say "Best match: " ~ @matches.head.dist.identity;

    =end code

    =head1 Description

    A C<Repository> that uses 1 or more other C<Repository> instances as backends. It abstracts the logic
    for e.g. sorting by version from multiple repositories. Each C<Repository> (including this one and
    whatever backends this may use) can be thought of as recommendation managers, where C<Zef::Repository>
    gives a recommendation based on recommendations it gets from its backends (i.e. fez, p6c, cpan, cached).

    =head1 Methods

    =head2 method candidates

        method candidates(*@identities ($, *@) --> Array[Candidate])

    Resolves each identity in C<@identities> to its best matching C<Candidate>, where the "best match" is generally
    what is most consistent with how C<Raku> would otherwise load modules.

    Each repository makes its own recommendations, and only then will the results be considered to make a single recommendation
    for each of C<@identities> from. For instance one ecosystem might return a C<Foo:ver(1)> and C<Foo:ver(3)>, and another a C<Foo:ver(2)>
    for an identity of C<Foo> -- this module emulates C<Raku> internal module resolution logic and will choose the best match (in this case
    C<Foo:ver(3)>.

    This module purposely does not combine multiple ecosystems into a single list to make a recommendation from; by design it a recommendation
    manager for the results of recommendation managers. This allows more consistent resolution of dependencies and integration with MetaCPAN like
    services (which may not just provide an entire list of modules it has -- i.e. it makes it own recommendation for a name)

    Returns an C<Array> of C<Candidate>, where each C<Candidate> matches exactly one of the provided C<@identities> (and
    each C<@identities> matches zero or one of the C<Candidate>).

    method search

        method search(:$max-results, Bool :$strict, *@identities ($, *@), *%fields --> Array[Candidate])

    Resolves each identity in C<@identities> to all of its matching C<Candidates> from all backends (with C<$max-results> applying to
    each individual backend). If C<$strict> is C<False> then it will consider partial matches on module short-names (i.e. 'zef search HTTP'
    will get results for e.g. C<HTTP::UserAgent>).

    method store

        method store(*@dists --> Nil)

    Attempts to store/save/cache each C<@dist> to each backend repository that provides a C<store> method. Generally this is used when
    a module is fetched from e.g. fez so that C<Zef::Repository::LocalCache> can cache it for next time. Note distributions fetched from
    local paths (i.e. `zef install .`) do not generally get passed to this method.

    method available

        method available(*@plugins --> Array[Candidate])

    Returns an C<Array> of all C<Candidate> provided by all backend repositories that support the C<available> method (http-query-per-request
    repositories may not be able to provide this) and have a 'name' (as defined in its entry in C<resources/config.json>) matching any of
    those in C<@names> (i.e. C<zef list fez> will only show stuff from the 'fez' backend).

    method update

        method update(*@plugins --> Hash)

    Updates each ecosystem backend (generally downloading a p6c.json or cpan.json file, or updating the 'cached' index).

    Generally you won't care about the return result of this method, and indeed in the future maybe it should be removed. Usually we just want the
    effects to happen (updating all ecosystem backends), but C<Zef::CLI> currently relies on the return result to show how many distributions are
    in each ecosystem after updating.

    Returns a C<Hash> where the key is the ecosystem 'name' (as defined in its entry in C<resources/config.json>) and its values are the results
    of calling C<.available> on that ecosystem (i.e. an C<Array> of C<Candidate>).

    =end pod


    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    #| This is what is used to resolve dependencies.
    #| Similar to .search(...), except it only returns 1 result (the best match) for each identity provided
    #| i.e .search for Foo:ver<*> may return multiple versions, but .candidates would only ever return 1 even
    #| if it exists in multiple repositories/backends.
    method candidates(*@identities ($, *@) --> Array[Candidate]) {
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

            # Prefer candidates from Zef::Repository::Local to avoid re-downloading cached items
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

    #| This is what is used to search for identities.
    #| Similar to .candidates(...), except it will return more than one result per identity as appropriate.
    method search(:$max-results, Bool :$strict, *@identities ($, *@), *%fields --> Array[Candidate]) {
        return Nil unless @identities || %fields;

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

    #| Call 'store' on any Repository that provides that interface (by default just 'cached')
    method store(*@dists --> Nil) {
        for self!plugins.grep(*.^can('store')) -> $storage {
            $storage.?store(@dists);
        }
    }

    #| Get all candidates/distributions from each backend
    method available(*@plugins --> Array[Candidate]) {
        my @can-available = self!plugins(@plugins).grep: -> $plugin {
            note "Plugin '{$plugin.short-name}' does not support `.available` -- Skipping" unless $plugin.can('available'); # UNDO doesn't work here yet
            $plugin.can('available');
        }

        my @available = @can-available.race(:batch(1)).map({ $_.available.Slip });

        my Candidate @results = @available;
        return @results;
    }

    #| Update each Repository / backend
    method update(*@plugins --> Hash) {
        my @can-update = self!plugins(@plugins).grep: -> $plugin {
            note "Plugin '{$plugin.short-name}' does not support `.update` -- Skipping" unless $plugin.can('update'); # UNDO doesn't work here yet
            $plugin.can('update');
        }

        my %updates = @can-update.race(:batch(1)).map({ $_.update; $_.id => $_.available.elems }).hash;

        return %updates;
    }

    #| Like self.plugins this returns a list of plugins that Pluggable + @.backends provides, but also allows
    #| filtering which plugins are used by short-name (short-name is set in the config per Repository) so that
    #| things like `--update=fez` or `--/update=cpan` work.
    method !plugins(*@_) {
        +@_ ?? self.plugins.grep({.short-name ~~ any(@_)}) !! self.plugins
    }
}
