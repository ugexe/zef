role Zef::Roles::Hooking {
    # TODO:
    # Turn into hook cmd generator like build/test? 
    # Pair with commands passed to Zef::Roles::Processing?
    # Allow hooks to abort test based on exit code unless :$force
    # Better attempt at output displaying properly with StatusBar.pm6

    method hooks {
        my $hook-dir := $.path.child('hooks');
        my @hooks = ($hook-dir.IO.e && $hook-dir.IO.d)
            ?? $hook-dir.IO.ls(:f)
            !! ();
    }

    multi method run-hooks($phase, Bool :$before where *.so) {
        my @hooks := $.hooks();
        @hooks.grep(*.IO.basename.starts-with('before'))\
            .grep(*.IO.basename.ends-with("{$phase}.pl6"))\
            .map: { run($*EXECUTABLE, $_.IO.relative($.path), :cwd($.path)).status };
    }
    multi method run-hooks($phase, Bool :$after where *.so) {
        my @hooks := $.hooks();
        @hooks.grep(*.IO.basename.starts-with('after'))\
            .grep(*.IO.basename.ends-with("{$phase}.pl6"))\
            .map: { run($*EXECUTABLE, $_.IO.relative($.path), :cwd($.path)).status };
    }
}