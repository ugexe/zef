class Zef::Shell {
    # @.invocation is an optional list of arguments to be passed *first* to any shell/run calls
    # The purpose is to setup Procs we can spawn with different shell schematics (PowerShell for instance)
    # while still letting us create helper routines that accept positiona/slurpy parameters that for
    # example could be placed at the *end* of the arguments passed to run
    has @.invocation = $*DISTRO.is-win ?? ('cmd', '/c') !! ();

    method zrun(:$env, :$cwd = $*CWD, :$out, :$err, *%_, *@_) {
        my %env = ($env ?? $env.hash !! %*ENV.hash);
        my $proc = run(|@.invocation, |@_, :%env, :$cwd, :$out, :$err);
        ?$proc ?? $proc !! False;
    }

    # Pass in arguments to shell scripts via ENV. Positionals can be accessed at %*ENV<ZEF_SHELL_$POSITION>
    # Named arguments set themselves in %*ENV, overriding any existing values ( i.e. %*ENV{%_.keys} = %_.values )
    method zrun-script($cmd, :%env is copy = %*ENV, :$cwd = $*CWD, *@_, *%_) {
        my %zenv = |@_.map({state $arg++; "ZEF_SHELL_$arg" => $_ }), |%_;
        %zenv.map: {%env{$_.key} = $_.value};
        $ = $.zrun($cmd, :%env, :$cwd);
    }
}

sub zrun(:$env, :$cwd = $*CWD, :$out, :$err, *%_, *@_) is export {
    # clean up the %env due to a bug in Proc complaining when .key ~~ Any|Nil|etc
    my %env = ($env ?? $env.hash !! %*ENV.hash).grep({ .value ~~ Str }).hash;
    $ = Zef::Shell.new.zrun(|@_, |%_, :%env, :$cwd, :$out, :$err);
}
