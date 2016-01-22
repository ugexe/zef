use Zef;

class Zef::ContentStorage does DynLoader {
    has $.fetcher is rw;
    has $.cache   is rw;

    # Like search, but meant to return a single result for each specific identity string.
    method candidates(Bool :$upgrade, *@identities) {
        my @results = gather IDENTITY: for @identities -> $ident {
            STORE:
            for self.plugins -> $storage {
                if $storage.search($ident, :max-results(1)) -> @candi {
                    take ($storage.^name => @candi[0]);
                    ?$upgrade ?? next(STORE) !! next(IDENTITY)
                }
            }
        }

        ?$upgrade
            ?? @results.sort({ $^b.value cmp $^a.value })
            !! @results;
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
        for self.plugins -> $storage {
            %results{$storage.^name} = $storage.search(|@identities, |%fields, :$max-results);
        }
        %results;
    }

    method store(*@dists) {
        state @cacheable = self.plugins.grep(*.^can('store'));
        for @cacheable -> $storage {
            $storage.?store(|@dists);
        }
    }

    method update(*@names) {
        # todo: tag on `name` from config to plugins to enable filter by name
        # +@names
        #    ?? self.plugins.grep(*.<name> ~~ any(@names)).map(*.?update)
        #    !! self.plugins.map(*.?update);
        self.plugins.map(*.?update);
    }

    method plugins {
        state @usable = @!backends.grep({
                !$_<disabled>
            &&  ((try require ::($ = $_<module>)) !~~ Nil)
            &&  (::($ = $_<module>).^can("probe") ?? ::($ = $_<module>).probe !! True)
            ?? True !! False
        }).map: { ::($ = $_<module>).new( :$!fetcher, :$!cache, |($_<options> // []) ) }
    }
}
