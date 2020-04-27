class Zef { }

sub zrun(*@_, *%_) is export { run (|@_).grep(*.?chars), |%_ }
sub zrun-async(*@_, *%_) is export { Proc::Async.new( (|@_).grep(*.?chars), |%_ ) }

# rakudo must be able to parse json, so it doesn't
# make sense to require a dependency to parse it
sub from-json($text) is export {
    ::("Rakudo::Internals::JSON").from-json($text)
}

sub to-json(|c) is export {
    ::("Rakudo::Internals::JSON").to-json(|c)
}

# todo: define all the additional options in these signatures, such as passing :$jobs
# to `test` (for the prove command), how to handle existing files, etc

# A way to avoid printing everything to make --quiet option more univesal between plugins
# Need to create a messaging format to include the phase, file, verbosity level, progress,
# etc we may or may not display as neccesary. It's current usage is not finalized and
# any suggestions for this are well taken
role Messenger  {
    has $.stdout = Supplier.new;
    has $.stderr = Supplier.new;
}

enum LEVEL is export <FATAL ERROR WARN INFO VERBOSE DEBUG TRACE>;
enum STAGE is export <RESOLVE FETCH EXTRACT FILTER BUILD TEST INSTALL REPORT>;
enum PHASE is export <BEFORE START LIVE STOP AFTER>;

# Get a resource located at a uri and save it to the local disk
role Fetcher {
    method fetch($uri, $save-as) { ... }
    method fetch-matcher($uri) { ... }
}

# As a post-hook to the default fetchers we will need to extract zip
# files. `git` does this itself, so a git based Fetcher wouldn't need this
# although we could possibly add `--no-checkout` to `git`s fetch and treat
# Extract as the action of `--checkout $branch` (allowing us to "extract"
# a specific version from a commit/tag)
role Extractor {
    method extract($archive-file, $target-dir) { ... }
    method ls-files($archive-file) { ... }
    method extract-matcher($path) { ... }
}

# test a single file OR all the files in a directory (recursive optional)
role Tester {
    method test($path, :@includes) { ... }
    method test-matcher($path) { ... }
}

role Builder {
    method build($dist, :@includes) { ... }
    method build-matcher($path) { ... }
}

role Installer {
    method install($dist, :$cur, :$force) { ... }
    method install-matcher($dist) { ... }
}

role Reporter {
    method report($dist) { ... }
}

role Candidate {
    has $.dist;
    has $.as;        # Requested as (maybe a url, maybe an identity, maybe a path)
    has $.from;      # Recommended from (::Ecosystems, ::MetaCPAN, ::LocalCache)
    has $.uri is rw; # url, file path, etc
    has Bool $.is-dependency is rw;
    has $.build-results is rw;
    has $.test-results is rw;
}

role Repository {
    # An identifier like .^name but intended to differentiate between instances of the same class
    # For instance: ::Ecosystems<p6c> and ::Ecosystems<cpan> which would otherwise share the
    # same .^name of ::Ecosystems
    method id { $?CLASS.^name.split('+', 2)[0] }

    # max-results is meant so we can :max-results(1) when we are interested in using it like
    # `.candidates` (i.e. 1 match per identity) so we can stop iterating search plugins earlier
    method search(:$max-results, *@identities, *%fields --> Iterable) { ... }

    # Optional method currently being called after a search/fetch
    # to assist ::Repository::LocalCache in updating its MANIFEST path cache.
    # The concept needs more thought, but for instance a GitHub related repositories
    # could commit changes or push to a remote branch, and (as is now) the cs
    # ::LocalCache to update MANIFEST so we don't *have* to do a recursive folder search
    #
    # method store(*@dists) { }

    # Optional method for listing available packages. For p6c style repositories
    # where we have an index file this is easy. For metacpan style where we
    # make a remote query not so much (maybe it could list the most recent X
    # modules... or maybe it just doesn't implement it at all)
    # method available { }
}

# Used by the phase's loader (i.e Zef::Fetch) to test that the plugin can
# be used. for instance, ::Shell wrappers probe via `cmd --help`. Note
# that the result of .probe is cached by each phase loader
role Probeable {
    method probe returns Bool { ... }
}

role Pluggable {
    has $!plugins;
    has @.backends;

    sub DEBUG($plugin, $message) {
        say "[Plugin - {$plugin<short-name> // $plugin<module> // qq||}] $message"\
            if ?%*ENV<ZEF_PLUGIN_DEBUG>;
    }

    method plugins(*@names) {
        +@names ?? self!list-plugins.grep({@names.contains(.short-name)}) !! self!list-plugins;
    }

    method !list-plugins {
        gather for @!backends -> $plugin {
            my $module = $plugin<module>;
            DEBUG($plugin, "Checking: {$module}");

            # default to enabled unless `"enabled" : 0`
            next() R, DEBUG($plugin, "\t(SKIP) Not enabled")\
                if $plugin<enabled>:exists && (!$plugin<enabled> || $plugin<enabled> eq "0");

            next() R, DEBUG($plugin, "\t(SKIP) Plugin could not be loaded")\
                if (try require ::($ = $module)) ~~ Nil;

            DEBUG($plugin, "\t(OK) Plugin loaded successful");

            if ::($ = $module).^find_method('probe') {
                ::($ = $module).probe
                    ?? DEBUG($plugin, "\t(OK) Probing successful")
                    !! (next() R, DEBUG($plugin, "\t(SKIP) Probing failed"))
            }

            # add attribute `short-name` here to make filtering by name slightly easier
            # until a more elegant solution can be integrated into plugins themselves
            my $class = ::($ = $module).new(|($plugin<options> // []))\
                but role :: { has $.short-name = $plugin<short-name> // '' };

            next() R, DEBUG($plugin, "(SKIP) Plugin unusable: initialization failure")\
                unless ?$class;

            DEBUG($plugin, "(OK) Plugin is now usable: {$module}");
            take $class;
        }
    }
}
