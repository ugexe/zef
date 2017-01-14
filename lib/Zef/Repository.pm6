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
            for $storage.search(|@search-for, :strict) -> $candi {
                take $candi;
            }
        }
        my @reduced = gather for @candis.categorize(*.dist.name).values -> $candis {
            # Put the cache in front so if its one of multiple sources with the identity it gets used
            my $prefer-order := $candis.sort({ $^a.^name ne 'Zef::Repository::LocalCache '});

            take $prefer-order.sort({ Version.new($^b.dist.version) <=> Version.new($^a.dist.version) }).head;
        }
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
