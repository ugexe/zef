use Zef;

class Zef::ContentStorage does DynLoader {
    has $.fetcher;
    has $.cache;

    # like search, but meant to return a single result for each specific identity string
    method candidates(*@identities) {
        my %results;
        IDENTITY:
        for @identities -> $ident {
            STORE:
            for self.plugins -> $storage {
                # todo: better way / option for knowing when to pass in a fetcher
                if $storage.search($ident, :max-results(1)) -> @candi {
                    %results{$storage.^name} .= append( @candi[0] );
                    next IDENTITY;
                }
            }
        }
        %results;
    }

    method search(:$max-results = 5, *@identities, *%fields) {
        return () unless @identities || %fields;
        my %results;
        for self.plugins -> $storage {
            %results{$storage.^name} = $storage.search(|@identities, |%fields, :$max-results);
        }
        %results;
    }

    method plugins {
        state @usable = @!backends\
            .grep({ !$_<disabled> })\
            .grep({ (try require ::($ = $_<module>)) !~~ Nil })\
            .grep({ ::($ = $_<module>).^can("probe") ?? ::($ = $_<module>).probe !! True })\
            .map({ ::($ = $_<module>).new( :$!fetcher, :$!cache, |($_<options> // []) ) });
    }
}
