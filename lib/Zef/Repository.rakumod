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
            { module => "Zef::Service::Shell::wget" },
        ];
        my $fetcher = Zef::Fetch.new(:backends(@fetching_backends));
        my $cache   = $*TMPDIR.child("{time}") andthen { mkdir $_ unless $_.IO.e };

        # Create repo using a backend that is essentially just: Zef::Repository::Ecosystems.new(|%options-shown-below)
        # Note usually options are all Str so they can be set in the config file, but for the time being the cache
        # and fetcher objects need to be passed in here as well (currently auto-magically done in Zef::Client but could
        # be done in Zef::Repository)
        my $repo = Zef::Repository.new(
            backends => [
                [
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
            ]
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

    One difference in how recommendations are made from raku is that repos are grouped. Given pseudo backends C<[[Eco1,Eco2],[Eco3]]> we see three
    repository backends in two different groups -- ecosystems in later groups are only searched if previous groups found no matches. This allows
    users to avoid dependency confusion attacks by allowing custom ecosystems to be the preferred source for whatever namespaces it provides
    regardless if another ecosystem later provides a module by the same name but higher version number.

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
        my %searchable = @identities.grep({ not $_.starts-with("." | "/") }).map({ $_ => 1 });

        my @unsorted-candis = eager gather GROUP: for self.plugins -> @repo-group {
            my @look-for = %searchable.grep(*.value).hash.keys.sort;

            my $group-results := @repo-group.hyper(:batch(1)).map: -> $repo {
                my @search-for = $repo.id eq 'Zef::Repository::LocalCache' ?? @identities !! @look-for;
                $repo.search(@search-for, :strict);
            }

            for $group-results.flat -> $dist {
                %searchable{$dist.as} = 0;
                take $dist;
            }            

            last GROUP unless %searchable.values.grep(*.so).so;
        }

        my @unsorted-grouped-candis = @unsorted-candis.grep(*.defined).categorize({.as}).values;

        # Take the distribution with the highest version out of all matching distributions from each repository
        my @sorted-candis = @unsorted-grouped-candis.map: -> $candis {
            my @presorted = $candis.sort(*.dist.ver).sort(*.dist.api);
            my $api       = @presorted.tail.dist.api;
            my $version   = @presorted.tail.dist.ver;

            my @sorted = @presorted.grep({ .dist.ver eq $version }).grep({ .dist.api eq $api });
            @sorted.tail;
        }

        # dedupe things the earlier `.as` categorization won't group right, like Foo:ver<1.0+> and Foo:ver<1.1+>
        my Candidate @results = @sorted-candis.unique(:as(*.dist.identity));
        return @results;
    }

    #| This is what is used to search for identities.
    #| Similar to .candidates(...), except it will return more than one result per identity as appropriate.
    method search(:$max-results, Bool :$strict, *@identities ($, *@), *%fields --> Array[Candidate]) {
        return Nil unless @identities || %fields;

        my @searchable = @identities.grep({ not $_.starts-with("." | "/") });

        my @unsorted-candis = eager gather GROUP: for self.plugins -> @repo-group {
            my $group-results := @repo-group.hyper(:batch(1)).map: -> $repo {
                $repo.search(@searchable, :$strict);
            }
            take $_ for $group-results.map(*.List).flat;
        }

        my Candidate @results = @unsorted-candis;
        return @results;
    }

    #| Call 'store' on any Repository that provides that interface (by default just 'cached')
    method store(*@dists --> Nil) {
        for self.plugins.map(*.List).flat.grep(*.^can('store')) -> $storage {
            $storage.?store(@dists);
        }
    }

    #| Get all candidates/distributions from each backend
    method available(*@plugins --> Array[Candidate]) {
        my @can-available = self.plugins(@plugins).map(*.List).flat.grep: -> $plugin {
            note "Plugin '{$plugin.short-name}' does not support `.available` -- Skipping" unless $plugin.can('available'); # UNDO doesn't work here yet
            $plugin.can('available');
        }

        my @available = @can-available.hyper(:batch(1)).map({ $_.available }).flat;

        my Candidate @results = @available;
        return @results;
    }

    #| Update each Repository / backend
    method update(*@plugins --> Nil) {
        my @can-update = self.plugins(@plugins).map(*.List).flat.grep: -> $plugin {
            note "Plugin '{$plugin.short-name}' does not support `.update` -- Skipping" unless $plugin.can('update'); # UNDO doesn't work here yet
            $plugin.can('update');
        }

        @can-update.race(:batch(1)).map({ $_.update });
    }
}
