use Zef;

class Zef::ContentStorage does Pluggable {
    has $.fetcher is rw;
    has $.cache   is rw;

    # Like search, but meant to return a single result for each specific identity string
    # whereas search is meant to search more fields and give many results to choose from
    method candidates(Bool :$upgrade, *@identities) {
        my @results = gather for self!plugins -> $storage {
            for $storage.search(|@identities) -> $result {
                my $dist := $result.value;
                my $c = Candidate.new(
                    dist           => $dist,
                    requested-as   => $result.key,
                    recommended-by => $storage.^name,
                    # The idea is to leave the original source-url alone and instead use a copy of
                    # source-url as a default if its not otherwise set. Using the metainfo hash
                    # (*not* the Distribution hash that gets saved) is a temporary solution
                    # until its natural location manifests itself. Note `source-url` or `from-uri`
                    # are not part of the meta spec
                    uri            => ($dist.metainfo<from-uri> || $dist.source-url),
                );
                take $c;
            }
        }

        # xxx: sux
        ?$upgrade
            ?? @results.sort({ $^b.dist cmp $^a.dist })
            !! @results;
    }

    # todo: Find a better way to allow plugins access to other plugins
    method !plugins {
        cache gather for self.plugins {
            .fetcher //= $!fetcher if .^can('fetcher');
            .cache   //= $!cache   if .^can('cache');
            take $_;
        }
    }

    # Need to map the given identities to what this returns like:
    # %results<Text::Table*> = [ from => $storage.^name, dists => $storage.search(|) ]
    # instead of the current:
    # %results{$storage.^name} = $storage.search(|)
    # Note that as each $storage is given all identities to search at once that the above will
    # likely involve a chance to the ContentStorage interfaces/plugins to handle this
    method search(:$max-results = 5, *@identities, *%fields) {
        return () unless @identities || %fields;
        my %results;
        for self!plugins -> $storage {
            %results{$storage.^name} = $storage.search(|@identities, |%fields, :$max-results);
        }
        %results;
    }

    method store(*@dists) {
        for self!plugins.grep(*.^can('store')) -> $storage {
            $storage.?store(|@dists);
        }
    }

    method update(*@names) {
        # todo: tag on `name` from config to plugins to enable filter by name
        # +@names
        #    ?? self.plugins.grep(*.<name> ~~ any(@names)).map(*.?update)
        #    !! self.plugins.map(*.?update);
        self!plugins.map(*.?update);
    }
}
