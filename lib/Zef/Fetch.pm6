use Zef;
use Zef::Utils::URI;

# the default fetchers are all shelled out. however 3rd party fetchers [see Zef.pm6 `role Fetcher`]
# (such as a pure perl6 http user agent) can be used by editing zef's config to provide the module name
class Zef::Fetch does Pluggable {

    method ACCEPTS($url) { $ = $url ~~ @$.plugins }

    method fetch($url, $save-as, :&stdout = -> $o {$o.say}, :&stderr = -> $e {$e.say}) {
        die "something went wrong fetching {$url} as path {$save-as} with {$.plugins.join(',')}"
            unless Zef::Utils::URI($url) && ($save-as.IO.parent.IO.e || mkdir($save-as.IO.parent));

        my $fetchers = self.plugins.grep(*.fetch-matcher($url));

        die "No fetching backend available" unless ?$fetchers;

        $fetchers[0].stdout.Supply.act(&stdout);
        $fetchers[0].stderr.Supply.act(&stderr);

        my $got = $fetchers[0].fetch($url, $save-as);

        $fetchers[0].stdout.done;
        $fetchers[0].stderr.done;

        return $got;
    }
}
