use Zef;
use Zef::Utils::FileSystem;
use Zef::Utils::URI;

# Both a 'Fetcher' and 'Extractor', this backend is for fetching (cp / copying files) and extracting (also cp / copying files).
# Both fetching and extracting work on local file paths. Fetching generally copies files into ~/.zef/tmp, and extracting copies
# files into ~/.zef/store

class Zef::Service::FetchPath does Fetcher does Messenger does Extractor {
    # Return true if this Fetcher understands the given uri/path
    method fetch-matcher($uri --> Bool:D) {
        # .is-absolute lets the app pass around absolute paths on windows and still work as expected
        my $is-pathy = so <. />.first({ $uri.starts-with($_) }) || $uri.IO.is-absolute;
        return so $is-pathy && $uri.IO.e;
    }

    # Return true if this Extractor understands the given uri/path
    method extract-matcher($uri --> Bool:D) {
        # .is-absolute lets the app pass around absolute paths on windows and still work as expected
        my $is-pathy = so <. />.first({ $uri.starts-with($_) }) || $uri.IO.is-absolute;
        return so $is-pathy && $uri.IO.d;
    }

    # Always return true since a file system is required
    method probe(--> Bool:D) { return True }

    # Fetch (copy) the given source path to the $save-to (+ timestamp if source-path is a directory) directory
    method fetch(IO() $source-path, IO() $save-to, --> IO::Path) {
        return False if !$source-path.e;
        return $source-path if $source-path.absolute eq $save-to.absolute; # fakes a fetch
        my $dest-path = $source-path.d ?? $save-to.child("{$source-path.IO.basename}_{time}") !! $save-to;
        mkdir($dest-path) if $source-path.d && !$save-to.e;
        return $dest-path if copy-paths($source-path, $dest-path).elems;
        return False;
    }

    # Extract (copy) the files located in $source-path directory to $save-to directory
    # This is mostly the same as fetch, and essentially allows the workflow to treat
    # any uri type (including paths) as if they can be extracted.
    method extract($source-path, $save-to) {
        my $extracted-to = $save-to.IO.child($source-path.IO.basename).absolute;
        my @extracted = copy-paths($source-path, $extracted-to);
        return +@extracted ?? $extracted-to !! Nil;
    }

    method ls-files($path) {
        return list-paths($path, :f, :!d, :r);
    }
}
