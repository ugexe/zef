module Zef:ver($?DISTRIBUTION.meta<version>):api($?DISTRIBUTION.meta<api>):auth($?DISTRIBUTION.meta<auth>) {
    our sub zrun(*@_, *%_) is export { run (|@_).grep(*.?chars), |%_ }
    our sub zrun-async(*@_, *%_) is export { Proc::Async.new( (|@_).grep(*.?chars), |%_ ) }

    # rakudo must be able to parse json, so it doesn't
    # make sense to require a dependency to parse it
    our sub from-json($text) { ::("Rakudo::Internals::JSON").from-json($text) }
    our sub to-json(|c) { ::("Rakudo::Internals::JSON").to-json(|c) }

    enum LEVEL is export <FATAL ERROR WARN INFO VERBOSE DEBUG TRACE>;
    enum STAGE is export <RESOLVE FETCH EXTRACT FILTER BUILD TEST INSTALL REPORT>;
    enum PHASE is export <BEFORE START LIVE STOP AFTER>;

    # Get a resource located at a uri and save it to the local disk
    role Fetcher is export {
        method fetch($uri, $save-as) { ... }
        method fetch-matcher($uri) { ... }
    }

    # As a post-hook to the default fetchers we will need to extract zip
    # files. `git` does this itself, so a git based Fetcher wouldn't need this
    # although we could possibly add `--no-checkout` to `git`s fetch and treat
    # Extract as the action of `--checkout $branch` (allowing us to "extract"
    # a specific version from a commit/tag)
    role Extractor is export {
        method extract($archive-file, $target-dir) { ... }
        method ls-files($archive-file) { ... }
        method extract-matcher($path) { ... }
    }

    # test a single file OR all the files in a directory (recursive optional)
    role Tester is export {
        method test($path, :@includes, :$stdout, :$stderr) { ... }
        method test-matcher($path) { ... }
    }

    role Builder is export {
        method build($dist, :@includes, :$stdout, :$stderr) { ... }
        method build-matcher($path) { ... }
    }

    role Installer is export {
        method install($dist, :$cur, :$force) { ... }
        method install-matcher($dist) { ... }
    }

    role Reporter is export {
        method report($dist) { ... }
    }

    role Candidate is export {
        has $.dist;
        has Str $.as;              # Requested as (maybe a url, maybe an identity, maybe a path)
        has Str() $.from;          # Recommended from (::Ecosystems, ::LocalCache)
        has Str() $.uri is rw;     # url, file path, etc
        has $.build-results is rw;
        has $.test-results is rw;
    }

    role PackageRepository is export {
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

        # Optional method that tells a repository to 'sync' its database.
        # Useful for repositories that store the database / file locally.
        # Not useful for query based resolution e.g. metacpan
        # method update { }
    }

    # Used by the phase's loader (i.e Zef::Fetch) to test that the plugin can
    # be used. for instance, ::Shell wrappers probe via `cmd --help`. Note
    # that the result of .probe is cached by each phase loader
    role Probeable is export {
        method probe (--> Bool) { ... }
    }

    role Pluggable is export {
        #| Stringified module names to load as a plugin
        has @.backends;

        #| All the loaded @.backend objects
        has $!plugins;

        sub DEBUG($plugin, $message) {
            say "[Plugin - {$plugin<short-name> // $plugin<module> // qq||}] $message"\
                if ?%*ENV<ZEF_PLUGIN_DEBUG>;
        }

        method plugins(*@short-names) {
            my $all-plugins := self!list-plugins;
            return $all-plugins unless +@short-names;

            my @plugins;
            for $all-plugins -> @plugin-group {
                if @plugin-group.grep(-> $plugin { $plugin.short-name ~~ any(@short-names) }) -> @filtered-group {
                    push @plugins, @filtered-group;
                }
            }
            return @plugins;
        }

        has $!list-plugins-lock = Lock.new;
        method !list-plugins(@backends = @!backends) {
            $!list-plugins-lock.protect: {
                return $!plugins if $!plugins.so;

                # @backends used to only be an array of hash. However now the ::Repository
                # section of the config an an array of an array of hash and thus the logic
                # below was adapted (it wasn't designed this way from the start).
                my @plugins;
                for @backends -> $backend {
                    if $backend ~~ Hash {
                        if self!try-load($backend) -> $class {
                            push @plugins, $class;
                        }
                    }
                    else {
                        my @group;
                        for @$backend -> $plugin {
                            if self!try-load($plugin) -> $class {
                                push @group, $class;
                            }
                        }
                        push( @plugins, @group ) if +@group;
                    }
                }
                return $!plugins := @plugins
            }
        }

        method !try-load(Hash $plugin) {
            my $module = $plugin<module>;
            DEBUG($plugin, "Checking: {$module}");

            # default to enabled unless `"enabled" : 0`
            if $plugin<enabled>:exists && (!$plugin<enabled> || $plugin<enabled> eq "0") {
                DEBUG($plugin, "\t(SKIP) Not enabled");
                return;
            }

            if (try require ::($module)) ~~ Nil {
                DEBUG($plugin, "\t(SKIP) Plugin could not be loaded");
                return;
            }

            DEBUG($plugin, "\t(OK) Plugin loaded successful");

            if ::($module).^find_method('probe') {
                unless ::($module).probe {
                    DEBUG($plugin, "\t(SKIP) Probing failed");
                    return;
                }
                DEBUG($plugin, "\t(OK) Probing successful")
            }

            # add attribute `short-name` here to make filtering by name slightly easier
            # until a more elegant solution can be integrated into plugins themselves
            my $class = ::($module).new(|($plugin<options> // []))\
                but role :: { has $.short-name = $plugin<short-name> // '' };

            # make the class name more human readable for cli output,
            # i.e. Zef::Service::Shell::curl instead of Zef::Service::Shell::curl+{<anon|1>}
            $class.^set_name($module);

            unless ?$class {
                DEBUG($plugin, "(SKIP) Plugin unusable: initialization failure");
                return;
            }

            DEBUG($plugin, "(OK) Plugin is now usable: {$module}");
            return $class;
        }
    }
}

class X::Zef::UnsatisfiableDependency is Exception {
    method message() {
        'Failed to resolve some missing dependencies'
    }
}
