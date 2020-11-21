use Zef;
use Zef::Utils::URI;

# Handles git based abstractions.
# Both a 'Fetcher' and 'Extractor', this backend is for fetching (clone, pull) and extracting (checkout)
# git uris. Fetching works with local and remote repo uris. Extracting works with local repo uris.

class Zef::Service::Shell::git does Fetcher does Extractor does Probeable does Messenger {
    # This is for overriding the uri scheme used for git, i.e. force https:// over git://
    has Str $.scheme;

    # Return true if the `git` command is available to use
    method probe(--> Bool:D) {
        state $probe = try { run('git', '--help', :!out, :!err).so };
    }

    # Return true if this Fetcher understands the given uri/path
    method fetch-matcher($orig-url --> Bool:D) {
        # $orig-uri may contain non-uri-standard, git specific, uri parts (like a trailing @tag)
        my $url = self!repo-url($orig-url).lc;
        return False unless $url.ends-with('.git');
        return so <git http ssh>.first({ $url.starts-with($_) });
    }

    # Return true if this Extractor understands the given uri/path
    method extract-matcher($str --> Bool:D) {
        return False unless $str.IO.d;
        # When used to 'extract' we want to ensure the path is a git repository (which may use a non-standard .git dir location)
        my $proc = zrun('git', 'status', :!out, :!err, :cwd($str));
        return $proc.so;
    }

    # Fetch the given url
    # First attempts to clone the repository, but if it already exists (or fails) it attempts to pull down new changes
    method fetch($url, IO() $save-as --> IO::Path) {
        return self!clone(self!repo-url($url), $save-as) || self!pull($save-as);
    }

    # Extracts the given path
    # For a git repo extraction is equivalent to checking out a specific revision and copying it to separate location
    method extract(IO() $repo-path, IO() $extract-to) {
        die "target repo directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $sha1 = self!rev-parse(self!fetch($repo-path)).head;
        die "target repo directory {$repo-path.absolute} failed to locate checkout revision"
            unless $sha1;

        my $checkout-to = $extract-to.child($sha1);
        die "target repo directory {$extract-to.absolute} does not exist and could not be created"
            unless ($checkout-to.e && $checkout-to.d) || mkdir($checkout-to);

        return self!checkout($repo-path, $checkout-to, $sha1);
    }

    # Returns an array of strings, where each string is a relative path representing a file that can be extracted from the given $repo-path
    method ls-files(IO() $repo-path --> Array[Str]) {
        die "target repo directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $passed;
        my $output = Buf.new;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', 'ls-tree', '-r', '--name-only', self!checkout-name($repo-path));
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-paths = $output.decode.lines;

        my Str @results = $passed ?? @extracted-paths.grep(*.defined) !! ();
        return @results;
    }

    # On success returns an IO::Path to where a `git clone ...` has put files
    method !clone($url, IO() $save-as --> IO::Path) {
        die "target download directory {$save-as.absolute} does not exist and could not be created"
            unless $save-as.d || mkdir($save-as);

        my $passed;
        react {
            my $cwd := $save-as.parent;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', 'clone', $url, $save-as.basename, '--quiet');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return ($passed && $save-as.child('.git').d) ?? $save-as !! Nil;
    }

    # Does a `git pull` on an existing local git repo
    method !pull(IO() $repo-path --> IO::Path) {
        die "target download directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $passed;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', 'pull', '--quiet');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return $passed ?? $repo-path !! Nil;
    }

    # Does a `git fetch` on an existing local git repo. Not really related to self.fetch(...)
    method !fetch(IO() $repo-path --> IO::Path) {
        die "target download directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $passed;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', 'fetch', '--quiet');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return $passed ?? $repo-path !! Nil;
    }

    # Does a `git checkout ...`, allowing git source urls to have e.g. trailing @tag
    method !checkout(IO() $repo-path, IO() $extract-to, $target --> IO::Path) {
        my $passed;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', '--work-tree', $extract-to, 'checkout', $target, '.');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return $passed ?? $extract-to !! Nil;
    }

    # Does a `git rev-parse ...` (used to get a sha1 for saving a copy of a specific checkout)
    method !rev-parse(IO() $save-as --> Array[Str]) {
        die "target repo directory {$save-as.absolute} does not contain a .git/ folder"
            unless $save-as.child('.git').d;

        my $passed;
        my $output = Buf.new;
        react {
            my $cwd := $save-as.absolute;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', 'rev-parse', self!checkout-name($save-as));
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-refs = $output.decode.lines;

        my Str @results = $passed ?? @extracted-refs.grep(*.defined) !! ();
        return @results;
    }

    # Git URI parser / transformer
    # Handles overriding the uri $.scheme, and removing parts of the URI that e.g. `git clone ...` wouldn't understand
    # (like a trailing @tag on the uri)
    method !repo-url($url --> Str) {
        my $uri = uri($!scheme ?? $url.subst(/^\w+ '://'/, "{$!scheme}://") !! $url) || return False; #'
        my $reconstructed-uri = ($uri.scheme // '') ~ '://' ~ ($uri.user-info ?? "{$uri.user-info}@" !! '') ~ ($uri.host // '') ~ ($uri.path // '').subst(/\@.*[\/|\@|\?|\#]?$/, '');
        return $reconstructed-uri;
    }

    # Given a $url like http://foo.com/project.git@v1 or ./project.git@v1 will return 'v1'
    method !checkout-name($url --> Str) {
        my $uri      = uri($url) || return False;
        my $checkout = ($uri.path // '').match(/\@(.*)[\/|\@|\?|\#]?/)[0];
        return $checkout ?? $checkout.Str !! 'HEAD';
    }
}
