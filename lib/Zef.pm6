class Zef { }

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
    method list($archive-file) { ... }
    method extract-matcher($path) { ... }
}

# test a single file OR all the files in a directory (recursive optional)
role Tester {
    method test($path, :@includes) { ... }
    method test-matcher($path) { ... }
}

role ContentStorage {
    # max-results is meant so we can :max-results(1) when we are interested in using it like
    # `.candidates` (i.e. 1 match per identity) so we can stop iterating search plugins earlier
    method search(:$max-results, *@identities, *%fields) { ... }

    # Optional method currently being called after a search/fetch
    # to assist ::ContentStorage::LocalCache in updating its MANIFEST path cache.
    # The concept needs more thought, but for instance a GitHub related storage
    # could commit changes or push to a remote branch, and (as is now) the cs
    # ::LocalCache to update MANIFEST so we don't *have* to do a recursive folder search
    #
    # method store(*@dists) { }
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

    method plugins {
        my $DEBUG=1;
        sub DEBUG($plugin, $message) {
            say "[Plugin - {$plugin<name> // qq||}] $message" if $DEBUG;
        }

        $!plugins := $!plugins ?? $!plugins !! cache gather for @!backends -> $plugin {
            my $module = $plugin<module>;
            DEBUG($plugin, "Checking: {$module}");

            if $plugin<enabled>:exists && !$plugin<enabled> {
                DEBUG($plugin, "\t(SKIP) Not enabled");
                next;
            }

            if (try require ::($ = ~$module)) ~~ Nil {
                DEBUG($plugin, "\t(SKIP) Plugin could not be loaded");
                next;
            }
            DEBUG($plugin, "\t(OK) Plugin loaded successful");

            if ::($ = $module).^can("probe") {
                unless ::($ = $module).probe {
                    DEBUG($plugin, "\t(SKIP) Probing failed");
                    next;
                }
                DEBUG($plugin, "\t(OK) Probing successful");
            }

            my $class = ::($ = $module).new(|($plugin<options> // []));

            if ?$class {
                DEBUG($plugin, "(OK) Plugin is now usable: {$module}");
                take $class;
            }
            else {
                DEBUG($plugin, "(SKIP) Plugin unusable: initialization failure");
            }
        }
    }
}
