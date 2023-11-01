use Zef:ver($?DISTRIBUTION.meta<version> // '*'):api($?DISTRIBUTION.meta<api> // '*'):auth($?DISTRIBUTION.meta<auth> // '');
use Zef::Utils::URI:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth) :internals;

class Zef::Service::Shell::git does Fetcher does Extractor does Probeable {

    =begin pod

    =title class Zef::Service::Shell::git

    =subtitle A git based implementation of the Fetcher and Extractor interfaces

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::git;

        my $git = Zef::Service::Shell::git.new;

        # Fetch the git repository
        my $tag-or-sha = "@v0.9.0";
        my $source     = "https://github.com/ugexe/zef.git{$tag-or-sha}";
        my $save-to    = $*CWD.child("backup_dir{$tag-or-sha}"); # must include tag in save path currently :/
        my $saved-to   = $git.fetch($source, $save-to);

        say "Zef META6 from HEAD: ";
        say $saved-to.child("META6.json").slurp;

        # Extract the repository
        my $extract-to   = $*CWD.child("extracted_backup_dir");
        my $extracted-to = $git.extract($saved-to, $extract-to);

        say "Zef META6 from older $tag-or-sha: ";
        say $extracted-to.dir.first({ .basename eq "META6.json" }).slurp;

    =end code

    =head1 Description

    C<Fetcher> and C<Extractor> class for handling git URIs using the C<git> command.

    You probably never want to use this unless its indirectly through C<Zef::Fetch> or C<Zef::Extractor>;
    handling files and spawning processes will generally be easier using core language functionality. This
    class exists to provide the means for cloning git repos and checking out revisions using the C<Fetcher>
    and C<Extractor> interfaces that the e.g. http/tar fetching/extracting adapters use.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully launch the C<git> command.

    =head2 method fetch-matcher

        method fetch-matcher(Str() $uri --> Bool:D)

    Returns C<True> if this module knows how to fetch C<$uri>, which it decides based on if a parsed C<$uri>
    ends with C<.git> (including local directories) and starts with any of C<http> C<git> C<ssh>.

    =head2 method extract-matcher

        method extract-matcher(Str() $uri --> Bool:D) 

    Returns C<True> if this module knows how to extract C<$uri>, which it decides based on if a parsed C<$uri>
    looks like a directory and if C<git status> can successfully be run from that directory.

    =head2 method fetch

        method fetch(Str() $uri, IO() $save-to, Supplier :$stdout, Supplier :$stderr --> IO::Path)

    Fetches the given C<$uri> via C<git clone $uri $save-to>, or via C<git pull> if C<$save-to> is an existing git repo.
    A C<Supplier> can be supplied as C<:$stdout> and C<:$stderr> to receive any output.

    On success it returns the C<IO::Path> where the data was actually saved to. On failure it returns C<Nil>.

    =head2 method extract

        method extract(IO() $repo-path, IO() $extract-to, Supplier :$stdout, Supplier :$stderr)

    Extracts the given C<$repo-path> from the file system to C<$save-to> via C<git checkout ...>. A C<Supplier> can
    be supplied as C<:$stdout> and C<:$stderr> to receive any output.

    On success it returns the C<IO::Path> where the data was actually extracted to. On failure it returns C<Nil>.

    =head2 method ls-files

        method ls-files(IO() $repo-path --> Array[Str])

    On success it returns an C<Array> of relative paths that are available to be extracted from C<$repo-path>.

    =end pod


    #| This is for overriding the uri scheme used for git, i.e. force https:// over git://
    has Str $.scheme;

    my Lock $probe-lock = Lock.new;
    my Bool $probe-cache;

    #| Return true if the `git` command is available to use
    method probe(--> Bool:D) {
        $probe-lock.protect: {
            return $probe-cache if $probe-cache.defined;
            my $probe is default(False) = try so run('git', '--help', :!out, :!err);
            return $probe-cache = $probe;
        }
    }

    #| Return true if this Fetcher understands the given uri/path
    method fetch-matcher(Str() $uri --> Bool:D) {
        # $uri may contain non-uri-standard, git specific, uri parts (like a trailing @tag)
        my $clean-uri = self!repo-url($uri).lc;
        return False unless $clean-uri.ends-with('.git');
        return so <git http ssh>.first({ $clean-uri.starts-with($_) });
    }

    #| Return true if this Extractor understands the given uri/path
    method extract-matcher(Str() $uri --> Bool:D) {
        return False unless $uri.IO.d;
        # When used to 'extract' we want to ensure the path is a git repository (which may use a non-standard .git dir location)
        my $proc = Zef::zrun('git', 'status', :!out, :!err, :cwd($uri));
        return $proc.so;
    }

    #| Fetch the given url.
    #| First attempts to clone the repository, but if it already exists (or fails) it attempts to pull down new changes
    method fetch(Str() $uri, IO() $save-as, Supplier :$stdout, Supplier :$stderr --> IO::Path) {
        return self!clone(self!repo-url($uri), $save-as) || self!pull($save-as);
    }

    #| Extracts the given path.
    #| For a git repo extraction is equivalent to checking out a specific revision and copying it to separate location
    method extract(IO() $repo-path, IO() $extract-to, Supplier :$stdout, Supplier :$stderr) {
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

    #| Returns an array of strings, where each string is a relative path representing a file that can be extracted from the given $repo-path
    method ls-files(IO() $repo-path --> Array[Str]) {
        die "target repo directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $passed;
        my $output = Buf.new;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = Zef::zrun-async('git', 'ls-tree', '-r', '--name-only', self!checkout-name($repo-path));
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-paths = $output.decode.lines;

        my Str @results = $passed ?? @extracted-paths.grep(*.defined) !! ();
        return @results;
    }

    #| On success returns an IO::Path to where a `git clone ...` has put files
    method !clone($url, IO() $save-as --> IO::Path) {
        die "target download directory {$save-as.absolute} does not exist and could not be created"
            unless $save-as.d || mkdir($save-as);

        my $passed;
        react {
            my $cwd := $save-as.parent;
            my $ENV := %*ENV;
            my $proc = Zef::zrun-async('git', 'clone', $url, $save-as.basename, '--quiet');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return ($passed && $save-as.child('.git').d) ?? $save-as !! Nil;
    }

    #| Does a `git pull` on an existing local git repo
    method !pull(IO() $repo-path --> IO::Path) {
        die "target download directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $passed;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = Zef::zrun-async('git', 'pull', '--quiet');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return $passed ?? $repo-path !! Nil;
    }

    #| Does a `git fetch` on an existing local git repo. Not really related to self.fetch(...)
    method !fetch(IO() $repo-path --> IO::Path) {
        die "target download directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $passed;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = Zef::zrun-async('git', 'fetch', '--quiet');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return $passed ?? $repo-path !! Nil;
    }

    #| Does a `git checkout ...`, allowing git source urls to have e.g. trailing @tag
    method !checkout(IO() $repo-path, IO() $extract-to, $target --> IO::Path) {
        my $passed;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = Zef::zrun-async('git', '--work-tree', $extract-to, 'checkout', $target, '.');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        return $passed ?? $extract-to !! Nil;
    }

    #| Does a `git rev-parse ...` (used to get a sha1 for saving a copy of a specific checkout)
    method !rev-parse(IO() $save-as --> Array[Str]) {
        die "target repo directory {$save-as.absolute} does not contain a .git/ folder"
            unless $save-as.child('.git').d;

        my $passed;
        my $output = Buf.new;
        react {
            my $cwd := $save-as.absolute;
            my $ENV := %*ENV;
            my $proc = Zef::zrun-async('git', 'rev-parse', self!checkout-name($save-as));
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-refs = $output.decode.lines;

        my Str @results = $passed ?? @extracted-refs.grep(*.defined) !! ();
        return @results;
    }

    #| Git URI parser / transformer
    #| Handles overriding the uri $.scheme, and removing parts of the URI that e.g. `git clone ...` wouldn't understand
    #| (like a trailing @tag on the uri)
    method !repo-url($url --> Str) {
        my $uri = uri($!scheme ?? $url.subst(/^\w+ '://'/, "{$!scheme}://") !! $url) || return False; #'
        my $reconstructed-uri = ($uri.scheme // '') ~ '://' ~ ($uri.user-info ?? "{$uri.user-info}@" !! '') ~ ($uri.host // '') ~ ($uri.path // '').subst(/\@.*[\/|\@|\?|\#]?$/, '');
        return $reconstructed-uri;
    }

    #| Given a $url like http://foo.com/project.git@v1 or ./project.git@v1 will return 'v1'
    method !checkout-name($url --> Str) {
        my $uri      = uri($url) || return False;
        my $checkout = ($uri.path // '').match(/\@(.*)[\/|\@|\?|\#]?/)[0];
        return $checkout ?? $checkout.Str !! 'HEAD';
    }
}
