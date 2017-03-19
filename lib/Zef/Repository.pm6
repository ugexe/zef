use Zef;

class Zef::Repository does Pluggable {
    has $.fetcher is rw;
    has $.cache   is rw;

    method candidates(Bool :$upgrade, *@identities ($, *@)) {
        # todo: have a `file` identity in Zef::Identity
        my @searchable = @identities.grep({ not $_.starts-with("." | "/") });
        my @candis = gather for self!plugins -> $storage {
            # todo: (cont. from above): Each Repository should just filter this themselves
            my @search-for = $storage.id eq 'Zef::Repository::LocalCache' ?? @identities !! @searchable;
            for $storage.search(|@search-for, :strict) -> $candi { # :strict means exact short-name match
                take $candi;
            }
        }

        # Take the distribution with the highest version out of all matching distributions from all repositories
        my @ordered = gather for @candis.categorize(*.dist.name).values -> $candis {
            # Put the cache in front so if its one of multiple sources with the identity it gets used
            my $prefer-order := $candis.sort({ $^a.^name ne 'Zef::Repository::LocalCache '});

            take $prefer-order.sort({ Version.new($^b.dist.version) <=> Version.new($^a.dist.version) }).head;
        }

        # $candi.as tells us what string was used to request its distribution ($candi.dist)
        # So this is similar to the .categorize(*.dist.name) filter above, except it
        # covers when two different repositories have a matching candidate with different
        # distribution names (likely matching *module* names in provides)
        my @distinct-requested-as = @ordered.unique(:as(*.as));
    }

    # todo: Find a better way to allow plugins access to other plugins
    method !plugins(*@names) {
        cache gather for self.plugins(|@names) {
            .fetcher //= $!fetcher if .^can('fetcher');
            .cache   //= $!cache   if .^can('cache');
            take $_;
        }
    }

    method search(:$max-results = 5, Bool :$strict, *@identities ($, *@), *%fields) {
        return () unless @identities || %fields;
        my @results = eager gather for self!plugins -> $storage {
            take $_ for $storage.search(|@identities, |%fields, :$max-results, :$strict);
        }
        |@results;
    }

    method store(*@dists) {
        for self!plugins.grep(*.^can('store')) -> $storage {
            $storage.?store(|@dists);
        }
    }

    method available(*@from) {
        my %dists;
        my $check-plugins := +@from ?? self!plugins.grep({.short-name ~~ any(@from)}) !! self!plugins;
        my $candis := gather for $check-plugins.grep(*.^can('available')) -> $storage {
            take $_ for |$storage.available;
        }
    }

    method update(*@names) {
        eager gather for self!plugins(|@names) -> $plugin {
            next() R, warn "Specified plugin by name {$plugin.short-name} doesn't support `.update`"\
                if +@names && !$plugin.can('update'); # `.update` is an optional interface requirement
            take $plugin.id => $plugin.update.elems;
        }
    }
}
