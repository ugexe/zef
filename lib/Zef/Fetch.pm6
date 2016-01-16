use Zef;
use Zef::Utils::URI;

# the default fetchers are all shelled out. however 3rd party fetchers [see Zef.pm6 `role Fetcher`]
# (such as a pure perl6 http user agent) can be used by editing zef's config to provide the module name
class Zef::Fetch does DynLoader {
    method ACCEPTS($url) { $ = $url ~~ @$.plugins }

    method fetch($url, $save-as, :&stdout = -> $o {$o.say}, :&stderr = -> $e {$e.say}) {
        die "something went wrong fetching {$url} as path {$save-as} with {$.plugins.join(',')}"
            unless Zef::Utils::URI.parse($url) && ($save-as.IO.parent.IO.e || mkdir($save-as.IO.parent));
        my $fetcher = self.plugins.first(*.fetch-matcher($url));
        die "No fetching backend available" unless ?$fetcher;

        $fetcher.stdout.Supply.act(&stdout);
        $fetcher.stderr.Supply.act(&stderr);

        my $got = $fetcher.fetch($url, $save-as);

        $fetcher.stdout.done;
        $fetcher.stderr.done;

        return $got;
    }

    method plugins {
        state @usable = @!backends.grep({
                !$_<disabled>
            &&  ((try require ::($ = $_<module>)) !~~ Nil)
            &&  (::($ = $_<module>).^can("probe") ?? ::($ = $_<module>).probe !! True)
            ?? True !! False
        }).map: { ::($ = $_<module>).new( |($_<options> // []) ) }
    }
}
