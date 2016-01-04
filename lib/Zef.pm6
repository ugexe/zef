class Zef { }

# todo: define all the additional options in these signatures, such as passing :$jobs
# to `test` (for the prove command), how to handle existing files, etc

# A way to avoid printing everything to make --quiet option more univesal between plugins
role Messenger  {
    has $.out = Supplier.new;
}

# get a resource located at a uri and save it to the local disk
role Fetcher {
    method fetch($uri, $save-as) { ... }
    method fetch-matcher($uri) { ... }
}

# as a post-hook to the default fetchers we will need to extract zip
# files. git does this itself, so a git based Fetcher wouldn't need this
role Extractor {
    method extract($archive-file, $target-dir) { ... }
    method list($archive-file) { ... }
    method extract-matcher($path) { ... }
}

# test a single file OR all the files in a directory (recursive optional)
role Tester {
    method test($path) { ... }
    method test-matcher($path) { ... }
}

# used by the phase's loader (i.e Zef::Fetch) to test that the plugin can
# be used. for instance, ::Shell wrappers probe via `cmd --help`. Note
# that the result of .probe is cached by each phase loader
role Probeable {
    method probe returns Bool { ... }
}


role ContentStorage {
    method search(:$max-results, *@identities, *%fields) { ... }
}

role DynLoader {
    has @.backends;
    method plugins { ... }
}
