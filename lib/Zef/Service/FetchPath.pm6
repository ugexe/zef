use Zef;
use Zef::Utils::FileSystem;
use Zef::Utils::URI;

class Zef::Service::FetchPath does Fetcher does Messenger does Extractor {
    # .is-absolute lets the app pass around absolute paths on windows and still work as expected
    method fetch-matcher($uri)   { $ = (?$uri.IO.is-absolute || ?$uri.lc.starts-with('.' | '/')) && $uri.IO.e }
    method extract-matcher($uri) { $ = (?$uri.IO.is-absolute || ?$uri.lc.starts-with('.' | '/')) && $uri.IO.d }

    method probe { True }

    method fetch($from, $to) {
        return False    if !$from.IO.e;
        return $from    if $from.IO.absolute eq $to.IO.absolute; # fakes a fetch
        my $dest-path = $from.IO.d ?? $to.IO.child("{$from.IO.basename}_{time}") !! $to;
        mkdir($dest-path) if $from.IO.d && !$to.IO.e;
        return $dest-path if copy-paths($from, $dest-path).elems;
        False;
    }

    method extract($path, $save-as) {
        my $extracted-to = $save-as.IO.child($path.IO.basename).absolute;
        my @extracted = copy-paths($path, $extracted-to);
        +@extracted ?? $extracted-to !! False;
    }

    method ls-files($path) {
        $ = list-paths($path, :f, :!d, :r);
    }
}
