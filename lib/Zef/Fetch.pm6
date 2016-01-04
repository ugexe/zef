use Zef;

# the default fetchers are all shelled out. however 3rd party fetchers [see Zef.pm6 `role Fetcher`]
# (such as a pure perl6 http user agent) can be used by editing zef's config to provide the module name
class Zef::Fetch does DynLoader {
    method ACCEPTS($url) { $ = $url ~~ @$.plugins }

    method fetch($url, $save-as) {
        # todo: sanitize $url for any shell based fetchers
        if $save-as.IO.parent.IO.e || mkdir($save-as.IO.parent) {
            for self.plugins -> $fetcher {
                if $fetcher.fetch-matcher($url) {
                    return $fetcher.fetch($url, $save-as);
                }
            }
        }
        die "something went wrong fetching {$url} as path {$save-as} with {$.plugins.join(',')}";
    }

    method plugins {
        state @usable = @!backends\
            .grep({ (try require ::($ = $_<module>)) !~~ Nil })\
            .grep({ ::($ = $_<module>).^can("probe") ?? ::($ = $_<module>).probe !! True })\
            .map({ ::($ = $_<module>).new( |($_<options> // []) ) });
    }
}
