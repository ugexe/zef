enum Phase <BUILD TEST INSTALL>; # todo: have phases register themselves somewhere
role Zef::Roles::Hooking {
    # TODO:
    # Turn into hook cmd generator like build/test? 
    # Pair with commands passed to Zef::Roles::Processing?
    # Allow hooks to abort test based on exit code unless :$force
    # Better attempt at output displaying properly with StatusBar.pm6

    method !hook-files {
        my $hook-dir := $.path.child('hooks');
        state @hooks = ($hook-dir.IO.e && $hook-dir.IO.d)
            ?? $hook-dir.IO.ls(:f)
            !! ();
    }

    proto method hook-cmds(Phase $phase) {*}
    multi method hook-cmds(Phase $phase, Bool :$before where *.so) {
        nextwith($phase, 'before');
    }
    multi method hook-cmds(Phase $phase, Bool :$after where *.so) {
        nextwith($phase, 'after');
    }
    multi method hook-cmds(Phase $phase, $when?) {
        my @hooks = self!hook-files() or return ();
        @hooks .= grep(*.IO.basename.uc.ends-with("{$phase}.PL6"));
        @hooks .= grep(*.IO.basename.uc.starts-with($when.uc)) if $when;
        @hooks.sort.map: { [$*EXECUTABLE, $_.IO.relative($.path)] };
    }
}