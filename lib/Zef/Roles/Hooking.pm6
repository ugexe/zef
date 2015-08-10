enum Phase <BUILD TEST INSTALL>; # todo: have phases register themselves somewhere
role Zef::Roles::Hooking {
    # todo: Allow hooks to abort test based on exit code unless :$force

    method hook-files {
        $.path.child('hooks').IO.ls(:f);
    }

    proto method hook-cmds(Phase $phase) {*}
    multi method hook-cmds(Phase $phase, Bool :$before where *.so) {
        nextwith($phase, 'before');
    }
    multi method hook-cmds(Phase $phase, Bool :$after where *.so) {

        nextwith($phase, 'after');
    }
    multi method hook-cmds(Phase $phase, $when?) {
        my @hooks = $.hook-files.list\
            .grep({ $_.IO.basename.uc.ends-with("{$phase.uc}.PL6")    })\
            .grep({ !$when || $_.IO.basename.uc.starts-with($when.uc) })\
            .map: { [$*EXECUTABLE, $_.IO.relative($.path)]            }

        # temporary
        @hooks.push: $.legacy-builder-cmds
            if $phase ~~ BUILD && $when.lc eq 'before' && $.has-legacy-builder;

        @hooks;
    }

    # temporary
    method has-legacy-builder { $.path.child('Build.pm').IO.f }
    method legacy-builder-cmds {
        return unless $.has-legacy-builder;
        my $legacy-code = $.path.child('Build.pm');
        my $hooks-dir   = $.path.child('hooks');
        my $cmd         = "Build.new.build('{$.path}');";
        # last item has no affect on program execution, but allows STDMux to show `Build.pm` as the file name
        [$*EXECUTABLE, '-I.', '-MBuild', '-e', $.async ?? $cmd !! '"'~$cmd~'"', 'Build.pm'];
    }
}
