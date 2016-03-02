use Zef;

class Zef::ContentStorage does Pluggable {
    has $.fetcher is rw;
    has $.cache   is rw;

    # Like search, but meant to return a single result for each specific identity string
    # whereas search is meant to search more fields and give many results to choose from
    method candidates(Bool :$upgrade, *@identities) {
        # todo: have a `file` identity in Zef::Identity
        my @searchable = @identities.grep(!*.starts-with("." | "/"));
        my @results = gather for self!plugins -> $storage {
            # todo: (cont. from above): Each ContentStorage should just filter this themselves
            my $searchable := $storage.^name eq 'Zef::ContentStorage::LocalCache' ?? @identities !! @searchable;
            for $storage.search(|$searchable, :max-results(1)) -> $result {
                take $result;
            }
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

    method search(:$max-results = 5, *@identities, *%fields) {
        return () unless @identities || %fields;
        my @results = eager gather for self!plugins -> $storage {
            take $_ for $storage.search(|@identities, |%fields, :$max-results);
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
            take $plugin.^name.split('+', 2)[0] => $plugin.update.elems;
        }
    }
}
