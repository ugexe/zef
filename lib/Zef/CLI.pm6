use Zef;
use Zef::Client;
use Zef::Config;
use Zef::Utils::FileSystem;
use Zef::Identity;
use Zef::Distribution;
use Zef::Utils::SystemInfo;

# Content was cut+pasted from bin/zef, leaving bin/zef's contents as just: `use Zef::CLI;`
# This allows the bin/zef original code to be precompiled, halving bare start up time.
# Ideally this all ends up back in bin/zef once/if precompilation of scripts is handled in CURI
package Zef::CLI {
    my $verbosity = preprocess-args-verbosity-mutate(@*ARGS);
    %*ENV<ZEF_BUILDPM_DEBUG> = $verbosity >= DEBUG;
    my $CONFIG    = preprocess-args-config-mutate(@*ARGS);

    #| Download specific distributions
    multi MAIN('fetch', Bool :$force, *@identities ($, *@)) is export {
        my $client = get-client(:config($CONFIG) :$force);
        my @candidates = |$client.find-candidates(|@identities>>.&str2identity);
        abort "Failed to resolve any candidates. No reason to proceed" unless +@candidates;
        my @fetched    = |$client.fetch(|@candidates);
        my @fail       = |@candidates.grep: {.as !~~ any(@fetched>>.as)}

        say "!!!> Fetch failed: {.as}{?($verbosity >= VERBOSE)??' at '~.dist.path!!''}" for @fail;

        exit +@fetched && +@fetched == +@candidates && +@fail == 0 ?? 0 !! 1;
    }

    #| Run tests
    multi MAIN('test', Bool :$force, *@paths ($, *@)) is export {
        my $client     = get-client(:config($CONFIG) :$force);
        my @candidates = |$client.link-candidates( @paths.map(*.&path2candidate) );
        abort "Failed to resolve any candidates. No reason to proceed" unless +@candidates;
        my @tested = |$client.test(|@candidates);
        my (:@test-pass, :@test-fail) := @tested.classify: {.test-results.grep(*.so) ?? <test-pass> !! <test-fail> }

        say "!!!> Testing failed: {.as}{?($verbosity >= VERBOSE)??' at '~.dist.path!!''}" for @test-fail;

        exit ?@test-fail ?? 1 !! ?@test-pass ?? 0 !! 255;
    }

    #| Run Build.pm
    multi MAIN('build', Bool :$force, *@paths ($, *@)) is export {
        my $client = get-client(:config($CONFIG) :$force);
        my @candidates = |$client.link-candidates( @paths.map(*.&path2candidate) );
        abort "Failed to resolve any candidates. No reason to proceed" unless +@candidates;

        my @built = |$client.build(|@candidates);
        my (:@pass, :@fail) := @built.classify: {$_.?build-results !=== False ?? <pass> !! <fail> }

        say "!!!> Build failure: {.as}{?($verbosity >= VERBOSE)??' at '~.dist.path!!''}" for @fail;

        exit ?@fail ?? 1 !! ?@pass ?? 0 !! 255;
    }

    #| Install
    multi MAIN(
        'install',
        Bool :$depends       = True,
        Bool :$test-depends  = True,
        Bool :$build-depends = True,
        Bool :$test          = True,
        Bool :$fetch         = True,
        Bool :$build         = True,
        Bool :$force,
        Bool :$dry,
        Bool :$update,
        Bool :$upgrade,
        Bool :$depsonly,
        Bool :$serial,
        :$exclude is copy,
        :to(:$install-to) = $CONFIG<DefaultCUR>,
        *@wants ($, *@)
    ) is export {

        @wants .= map: *.&str2identity;
        my (:@paths, :@uris, :@identities) := @wants.classify: -> $wanted {
            $wanted ~~ /^[\. | \/]/                                           ?? <paths>
                !! ?Zef::Identity($wanted)                                    ?? <identities>
                !! (my $uri = Zef::Utils::URI($wanted) and !$uri.is-relative) ?? <uris>
                !! abort("Don't understand identity: {$wanted}");
        }

        my @excluded =  $exclude.map(*.&identity2spec);
        my $client   = get-client(:config($CONFIG) :exclude(|@excluded), :$force, :$depends, :$test-depends, :$build-depends);


        # LOCAL PATHS
        abort "The follow were recognized as file paths and don't exist as such - {@paths.grep(!*.IO.e)}"
            if +@paths.grep(!*.IO.e);
        my (:@wanted-paths, :@skip-paths) := @paths\
            .classify: {$client.is-installed(Zef::Distribution::Local.new($_).identity, :at($install-to.map(*.&str2cur))) ?? <skip-paths> !! <wanted-paths>}
        say "The following local paths candidates are already installed: {@skip-paths.join(', ')}"\
            if ($verbosity >= VERBOSE) && +@skip-paths;
        my @requested-paths = ?$force ?? @paths !! @wanted-paths;
        my @path-candidates = @requested-paths.map(*.&path2candidate);


        # URIS
        my @uri-candidates-to-check = $client.fetch( |@uris.map({ Candidate.new(:as($_), :uri($_)) }) ) if +@uris;
        abort "No candidates found matching uri: {@uri-candidates-to-check.join(', ')}" if +@uris && +@uri-candidates-to-check == 0;
        my (:@wanted-uris, :@skip-uris) := @uri-candidates-to-check\
            .classify: {$client.is-installed($_.dist.identity, :at($install-to.map(*.&str2cur))) ?? <skip-uris> !! <wanted-uris>}
        say "The following uri candidates are already installed: {@skip-uris.map(*.as).join(', ')}"\
            if ($verbosity >= VERBOSE) && +@skip-uris;
        my @requested-uris = (?$force ?? @uri-candidates-to-check !! @wanted-uris)\
            .grep: { $_ ~~ none(@path-candidates.map(*.dist.identity)) }
        my @uri-candidates = @requested-uris;


        # IDENTITIES
        my (:@wanted-identities, :@skip-identities) := @identities\
            .classify: {$client.is-installed($_, :at($install-to.map(*.&str2cur))) ?? <skip-identities> !! <wanted-identities>}
        say "The following candidates are already installed: {@skip-identities.join(', ')}"\
            if ($verbosity >= VERBOSE) && +@skip-identities;
        my @requested-identities = (?$force ?? @identities !! @wanted-identities)\
            .grep: { $_ ~~ none(@uri-candidates.map(*.dist.identity)) }
        my @requested  = |$client.find-candidates(:$upgrade, |@requested-identities) if +@requested-identities;
        abort "No candidates found matching identity: {@requested-identities.join(', ')}"\
            if +@requested-identities && +@requested == 0;


        my @prereqs    = |$client.find-prereq-candidates(|@path-candidates, |@uri-candidates, |@requested)\
            if +@path-candidates || +@uri-candidates || +@requested;
        my @candidates = grep *.defined, ?$depsonly
            ??|@prereqs !! (|@path-candidates, |@uri-candidates, |@requested, |@prereqs);

        unless +@candidates {
            note("All candidates are currently installed");
            exit(0) if $depsonly;
            abort("No reason to proceed. Use --force to continue anyway", 0) unless $force;
        }

        my (:@local, :@remote) := @candidates.classify: {.dist ~~ Zef::Distribution::Local ?? <local> !! <remote>}
        my @fetched = grep *.so, |@local, ($client.fetch(|@remote).Slip if +@remote);

        my CompUnit::Repository @to = $install-to.map(*.&str2cur);
        my @installed  = |$client.install( :@to, :$test, :$build, :$upgrade, :$update, :$dry, :$serial, |@fetched );
        my @fail       = |@candidates.grep: {.as !~~ any(@installed>>.as)}

        say "!!!> Install failures: {@fail.map(*.dist.identity).join(', ')}" if +@fail;
        exit +@installed && +@installed == +@candidates && +@fail == 0 ?? 0 !! 1;
    }

    #| Uninstall
    multi MAIN(
        'uninstall',
        Bool :$force,
        :from(:$uninstall-from) = $CONFIG<DefaultCUR>,
        *@identities ($, *@)
    ) is export {
        my $client = get-client(:config($CONFIG) :$force);
        my CompUnit::Repository @from = $uninstall-from.map(*.&str2cur);
        abort "Uninstall requires rakudo v2016.02 or later"\
            unless any(@from>>.can('uninstall'));

        my @uninstalled = $client.uninstall( :@from, |@identities>>.&str2identity );
        my @fail        = @identities.grep(* !~~ any(@uninstalled.map(*.as)));
        if +@uninstalled == 0 && +@fail {
            note("!!!> Found no matching candidates to uninstall");
            exit 1;
        }

        for @uninstalled.classify(*.from).kv -> $from, $candidates {
            say "===> Uninstalled from $from";
            say "$_" for |$candidates>>.dist>>.identity;
        }

        say "!!!> Failed to uninstall distributions: {@fail.join('. ')}" if +@fail;
        exit +@fail ?? 1 !! 0;
    }

    #| Get a list of possible distribution candidates for the given terms
    multi MAIN('search', Int :$wrap = False, *@terms ($, *@)) is export {
        my $client = get-client(:config($CONFIG));
        my @results = $client.search(|@terms);

        say "===> Found " ~ +@results ~ " results";

        my @rows = eager gather for @results -> $candi {
            FIRST { take [<ID From Package Description>] }
            take [ "{state $id += 1}", $candi.from, $candi.dist.identity, ($candi.dist.hash<description> // '') ];
        }
        print-table(@rows, :$wrap);

        exit 0;
    }

    #| A list of available modules from enabled repositories
    multi MAIN('list', Int :$max?, Bool :i(:$installed), *@at) is export {
        my $client = get-client(:config($CONFIG));

        my $found := ?$installed
            ?? $client.list-installed(|@at.map(*.&str2cur))
            !! $client.list-available(|@at);

        my $range := defined($max) ?? 0..+$max !! *;
        my %locations = $found[$range].classify: -> $candi { $candi.from }
        for %locations.kv -> $from, $candis {
            note "===> Found via {$from}";
            for |$candis -> $candi {
                say "{$candi.dist.identity}";
                say "#\t{$_}" for @($candi.dist.provides.keys.sort if ?($verbosity >= VERBOSE));
            }
        }

        exit 0;
    }

    #| Upgrade installed distributions (BETA)
    multi MAIN('upgrade', :to(:$install-to) = $CONFIG<DefaultCUR>, *@identities) is export {
        abort "Upgrading requires rakudo 2016.04 or later" unless try &*EXIT;

        # XXX: This is a very inefficient prototype inefficient
        my $client = get-client(:config($CONFIG));

        my @missing = @identities.grep: { not $client.is-installed($_) };
        abort "Can't upgrade identities that aren't installed: {@missing.join(', ')}" if +@missing;

        my @installed = $client.list-installed(|$install-to.map(*.&str2cur))
            .sort({Version.new($^b.dist.ver) > Version.new($^a.dist.ver)})
            .unique(:as({"{.dist.name}:ver<{.dist.auth-matcher}>"}));
        my @requested = +@identities
            ?? |$client.find-candidates(|@identities.map(*.&str2identity))
            !! |$client.find-candidates(|@installed.map(*.dist.clone(ver => "*")).map(*.identity).unique);
        my (:@upgradable, :@current) := @requested.classify: -> $candi {
            my $latest-installed = @installed.first({
                    .dist.name         eq $candi.dist.name
                &&  .dist.auth-matcher eq $candi.dist.auth-matcher
            });
            (($latest-installed.dist.ver cmp $candi.dist.ver) === Order::Less) ?? <upgradable> !! <current>;
        }
        abort "The following distributions are already at their latest versions: {@current.map(*.dist.identity).join(', ')}" if +@current;
        abort "All requested distributions are already at their latest versions" unless +@upgradable;

        # Sort these ahead of time so they can be installed individually by passing
        # the .uri instead of the identities (which would require another search)
        my @sorted-candidates = $client.sort-candidates(@upgradable);
        say "===> Updating: " ~ @sorted-candidates.map(*.dist.identity).join(', ');
        my (:@upgraded, :@failed) := @sorted-candidates.map(*.uri).classify: -> $uri {
            my &*EXIT = sub ($code) { return $code == 0 ?? True !! False };
            try &MAIN('install', $uri) ?? <upgraded> !! <failed>;
        }
        abort "!!!> Failed upgrading *all* modules" unless +@upgraded;

        say "!!!> Some modules failed to update: {@failed.map(*.dist.identity).join(', ')}" if +@failed;
        exit +@upgraded < +@upgradable ?? 1 !! 0;
    }

    #| View reverse dependencies of a distribution
    multi MAIN('rdepends', $identity) {
        my $client = get-client(:config($CONFIG));
        .dist.identity.say for $client.list-rev-depends($identity);
        exit 0;
    }

    #| Lookup locally installed distributions by short-name, name-path, or sha1 id
    multi MAIN('locate', $identity, Bool :$sha1) is export {
        my $client = get-client(:config($CONFIG));
        if !$sha1 {
            if $identity.ends-with('.pm' | '.pm6') {
                my $candi = $client.list-installed.first({
                    my $meta := $_.dist.compat.meta;
                    so $meta<provides>.values.grep({.keys[0] eq $identity});
                });

                if $candi {
                    my $libs = $candi.dist.compat.meta<provides>;
                    my $lib  = $libs.first({.value.keys[0] eq $identity});
                    say "===> From Distribution: {~$candi.dist}";
                    say "{$lib.keys[0]} => {$candi.from.prefix.child('sources').child($lib.value.values[0]<file>)}";
                    exit 0;
                }
            }
            elsif $identity.starts-with('bin/' | 'resources/') {
                my $candi = $client.list-installed.first({
                    my $meta := $_.dist.compat.meta;
                    so $meta<files>.first({.key eq $identity});
                });

                if $candi {
                    my $libs = $candi.dist.compat.meta<files>;
                    my $lib  = $libs.first({.key eq $identity});
                    say "===> From Distribution: {~$candi.dist}";
                    say "{$identity} => {$candi.from.prefix.child('resources').child($lib.value)}";
                    exit 0;
                }
            }
            elsif $client.resolve($identity) -> $candi {
                say "===> From Distribution: {~$candi.dist}";
                my $source-prefix = $candi.from.prefix.child('sources');
                my $source-path   = $source-prefix.child($candi.dist.compat.meta<provides>{$identity}.values[0]<file> // '');
                say "{$identity} => {$source-path}" if $source-path.IO.f;
                exit 0;
            }
        }
        else {
            my $candi = $client.list-installed.first({
                my $meta := $_.dist.compat.meta;
                my @source_files   = $meta<provides>.values.flatmap(*.values.map(*.<file>));
                my @resource_files = $meta<files>.values.first({$_ eq $identity});
                $identity ~~ any(grep *.defined, flat @source_files, @resource_files);
            });

            if $candi {
                say "===> From Distribution: {~$candi.dist}";
                $identity ~~ any($candi.dist.compat.meta<provides>.values.flatmap(*.values.map(*.<file>)))
                    ?? (say "{.keys[0]} => {$candi.from.prefix.child('sources').child(.values[0]<file>)}" for $candi.dist.compat.meta<provides>.values.grep(*.values.first({ .<file> eq $identity })).first(*.so))
                    !! (say "{.key} => {.value}" for $candi.dist.compat.meta<files>.first({.value eq $identity}));

                exit 0;
            }
        }

        say "!!!> Nothing located";

        exit 1;
    }

    #| Detailed distribution information
    multi MAIN('info', $identity, Int :$wrap = False) is export {
        my $client = get-client(:config($CONFIG));
        my $candi  = $client.resolve($identity)
                ||   $client.search($identity, :strict, :max-results(1))[0]\
                ||   abort "!!!> Found no candidates matching identity: {$identity}";
        my $dist  := $candi.dist;

        say "- Info for: $identity";
        say "- Identity: {$dist.identity}";
        say "- Recommended By: {$candi.from}";
        say "Author:\t {$dist.author}"                if $dist.author;
        say "Description:\t {$dist.description}"      if $dist.description;
        say "License:\t {$dist.compat.meta<license>}" if $dist.compat.meta<license>;
        say "Source-url:\t {$dist.source-url}"        if $dist.source-url;

        my @provides = $dist.provides.sort(*.key.chars);
        say "Provides: {@provides.elems} modules";
        if ?($verbosity >= VERBOSE) {

            my sub parse-value($str-or-kv) {
                do given $str-or-kv {
                    when Str  { $_ }
                    when Hash { $_.keys[0] }
                    when Pair { $_.key     }
                }
            }

            my $meta := $dist.compat.meta;
            my @rows = eager gather for @provides -> $lib {
                FIRST {
                    take $meta<provides>.values[0] ~~ Hash
                        ?? [<Module Path-Name File-ID>]
                        !! [<Module Path-Name>]
                }
                my $module-name = $lib.key;
                my $name-path   = parse-value($lib.value);
                my $real-path   = try { $meta<provides>{$module-name}{$name-path}<file> };
                take $real-path
                    ?? [ $module-name, $name-path, $real-path ]
                    !! [ $module-name, $name-path ];
            }
            print-table(@rows, :$wrap);
        }

        if $dist.hash<support> {
            say "Support:";
            for $dist.hash<support>.kv -> $k, $v {
                say "#   $k:\t$v";
            }
        }

        my @deps = (|$dist.depends-specs, |$dist.test-depends-specs, |$dist.build-depends-specs).grep(*.defined).unique;
        say "Depends: {@deps.elems} items";
        if ?($verbosity >= VERBOSE) {
            my @rows = eager gather for @deps -> $spec {
                FIRST { take [<ID Identity Installed?>] }
                my $row = [ "{state $id += 1}", $spec.name, ($client.is-installed($spec) ?? '✓' !! '')];
                take $row;
            }
            print-table(@rows, :$wrap);
        }

        exit 0;
    }

    #| Download a single module and change into its directory
    multi MAIN('look', $identity, Bool :$force) is export {
        my $client     = get-client(:config($CONFIG) :$force);
        my @candidates = |$client.find-candidates( str2identity($identity) );
        abort "Failed to resolve any candidates. No reason to proceed" unless +@candidates;
        my (:@remote, :@local) := @candidates.classify: {.dist !~~ Zef::Distribution::Local ?? <remote> !! <local>}
        my $fetched = @local[0] || $client.fetch(@remote[0])[0] || abort "Failed to fetch candidate: $identity";
        my $dist-path = $fetched.dist.path;
        say "===> Shelling into directory: {$dist-path}";
        exit so shell(%*ENV<SHELL> // %*ENV<ComSpec> // %*ENV<COMSPEC>, :cwd($dist-path)) ?? 0 !! 1;
    }

    #| Smoke test
    multi MAIN(
        'smoke',
        Bool :$depends       = True,
        Bool :$test-depends  = True,
        Bool :$build-depends = True,
        Bool :$test          = True,
        Bool :$fetch         = True,
        Bool :$build         = True,
        Bool :$force,
        Bool :$update,
        Bool :$upgrade,
        Bool :$depsonly,
        :$exclude is copy,
        :to(:$install-to) = $CONFIG<DefaultCUR>,
    ) is export {
        abort "Smoke testing requires rakudo 2016.04 or later" unless try &*EXIT;
        my @excluded   = $exclude.map(*.&identity2spec);
        my $client     = get-client(:config($CONFIG) :exclude(|@excluded), :$force, :$depends, :$test-depends, :$build-depends);
        my @identities = $client.list-available.map(*.dist.identity).unique;
        my CompUnit::Repository @to = $install-to.map(*.&str2cur);
        say "===> Smoke testing with {+@identities} distributions...";

        my &smoker = &MAIN.assuming(
            'install',
            :$depends,
            :$test-depends,
            :$build-depends,
            :$test,
            :$fetch,
            :$build,
            :$force,
            :$update,
            :$upgrade,
            :$depsonly,
            :$exclude,
            :$install-to,
            :$force,
        );

        for @identities -> $identity {
            # &*EXIT requires rakudo 2016.04
            my &*EXIT = sub ($code) { return $code == 0 ?? True !! False };
            my $result = try smoker($identity);
            say "===> Smoke result for {$identity}: {?$result??'OK'!!'NOT OK'}";
        }

        exit 0;
    }

    #| Update package indexes
    multi MAIN('update', *@names) is export {
        my $client  = get-client(:config($CONFIG));
        my %results = $client.recommendation-manager.update(|@names);
        my $rows    = |%results.map: {[.key, .value]};
        abort "An unknown plugin name used" if +@names && (+@names > +$rows);

        print-table( [["Content Storage", "Distribution Count"], |$rows], wrap => True );

        exit 0;
    }

    #| Nuke module installations (site, home) and repositories from config (RootDir, StoreDir, TempDir)
    multi MAIN('nuke', Bool :$confirm, *@names ($, *@)) {
        my sub dir-delete($dir) {
            my @deleted = grep *.defined, try delete-paths($dir, :f, :d, :r);
            say "Deleted " ~ +@deleted ~ " paths from $dir/*";
        }
        my sub confirm-delete(*@dirs) {
            for @dirs -> $dir {
                next() R, say "$dir does not exist. Skipping..." unless $dir.IO.e;
                given prompt("Delete {$dir.path}/* [y/n]: ") {
                    when any(<y Y>) { dir-delete($dir)   }
                    when any(<n N>) { say "Skipping..." }
                    default { say "Invalid entry (enter Y or N)"; redo }
                }
            }
        }

        my @config-keys = <RootDir StoreDir TempDir>;
        my @config-dirs = $CONFIG<<{@names (&) @config-keys}>>.map(*.IO.absolute).sort;

        my @curli-dirs = @names\
            .grep(* !~~ any(@config-keys))\
            .map(*.&str2cur)\
            .grep(*.?can-install)\
            .map(*.prefix.absolute);

        my @delete = |@curli-dirs, |@config-dirs;
        $confirm === False ?? @delete.map(*.&dir-delete) !! confirm-delete( |@delete );

        exit 0;
    }

    multi MAIN(Bool :h(:$help)?) {
        note qq:to/END_USAGE/
            Zef - Perl6 Module Management

            USAGE

                zef [flags|options] command [args]


            COMMANDS

                install                 Install specific dependencies by name or path
                uninstall               Uninstall specified distributions
                test                    Run tests on a given module's path
                fetch                   Fetch and extract module's source
                build                   Run the Build.pm in a given module's path
                look                    Fetch followed by shelling into the module's path
                update                  Update package indexes for repositories
                upgrade (BETA)          Upgrade specific distributions (or all if no arguments)
                search                  Show a list of possible distribution candidates for the given terms
                info                    Show detailed distribution information
                list                    List known available distributions, or installed distributions with `--installed`
                rdepends                List all distributions directly depending on a given identity
                locate                  Lookup installed module information by short-name, name-path, or sha1 (with --sha1 flag)
                smoke                   Run smoke testing on available modules
                nuke                    Delete directory/prefix containing matching configuration path or CURLI name

            OPTIONS

                --install-to=[name]     Short name or spec of CompUnit::Repository to install to
                --config-path=[path]    Load a specific Zef config file

            VERBOSITY LEVEL (from least to most verbose)
                --error, --warn, --info (default), --verbose, --debug

            FLAGS
                --depsonly              Install only the dependency chains of the requested distributions
                --force                 Continue each phase regardless of failures
                --dry                   Run all phases except the actual installations
                --serial                Install each dependency after passing testing and before building/testing the next dependency

                --/test                 Skip the testing phase
                --/build                Skip the building phase

                --/depends              Do not fetch runtime dependencies
                --/test-depends         Do not fetch test dependencies
                --/build-depends        Do not fetch build dependencies

            CONFIGURATION {$CONFIG.IO.absolute}
                Enable or disable plugins that match the configuration that has field `short-name` that matches <short-name>

                --<short-name>  # `--cpan`  Enable plugin with short-name `cpan`
                --/<short-name> # `--/cpan` Disable plugin with short-name `cpan`

            END_USAGE
    }

    proto sub abort(|) {*}
    multi sub abort(Int $exit-code, Str $str) { samewith($str, $exit-code) }
    multi sub abort(Str $str, Int $exit-code = 255) { say $str; exit $exit-code }

    # Filter/mutate out verbosity flags from @*ARGS and return a verbosity level
    sub preprocess-args-verbosity-mutate(*@_) {
        my (:@log-level, :@filtered-args) := @_.classify: {
            $_ ~~ any(<--fatal --error --warn --info -v --verbose --debug --trace>)
                ?? <log-level>
                !! <filtered-args>;
        }
        @*ARGS = @filtered-args;
        do given any(@log-level) {
            when '--fatal'   { FATAL   }
            when '--error'   { ERROR   }
            when '--warn'    { WARN    }
            when '--info'    { INFO    }
            when '--verbose' { VERBOSE }
            when '-v'        { VERBOSE }
            when '--debug'   { DEBUG   }
            when '--trace'   { TRACE   }
            default          { INFO    }
        }
    }

    # Second crack at cli config modification
    # Currently only uses Bools `--name` and `--/name` to enable and disable a plugin
    # Note that `name` can match the config plugin key `short-name` or `module`
    # * Now also removes --config-path $path parameters
    # TODO: Turn this into a more general getopts
    sub preprocess-args-config-mutate(*@args) {
        # get/remove --config-path=xxx
        # MUTATES @*ARGS
        my Str $config-path-from-args;
        for |@args.flatmap(*.split(/\=/, 2)).rotor(2 => -1, :partial) {
            $config-path-from-args = ~$_[1] if $_[0] eq '--config-path' && $_[1];
            LAST {
                @*ARGS = eager gather for |@args.kv -> $key, $value {
                    take($value) unless $value.starts-with('--config-path')
                        || ($key > 0 && @args[$key - 1] eq '--config-path')
                }
            }
        }
        my $chosen-config-file = $config-path-from-args // Zef::Config::guess-path();

        # Keep track of the original path so we can show it on the --help usage :-/
        my $config = do {
            # The .Str.IO thing is due to a weird rakudo bug I can't figure out .
            # A bare .IO will complain that its being called on a type Any (not true)
            my $path = $config-path-from-args // Zef::Config::guess-path;
            my $IO   = $path.Str.IO;
            my %hash = Zef::Config::parse-file($path).hash;
            class :: {
                has $.IO;
                has %.hash handles <AT-KEY EXISTS-KEY DELETE-KEY push append iterator list kv keys values>;
            }.new(:%hash, :$IO);
        }

        # - Move named options to start of @*ARGS so the git familiar style of options after positionals works
        # - get/remove --$short-name and --/$short-name where $short-name is a value in the config file
        my $plugin-lookup := Zef::Config::plugin-lookup($config.hash);
        for @*ARGS -> $arg {
            state @positional;
            state @named;
            LAST { @*ARGS = flat @named, @positional; }

            my $arg-as  = $arg.subst(/^["--" | "--\/"]/, '');
            my $enabled = $arg.starts-with('--/') ?? 0 !! 1;
            $arg.starts-with('-')
                ?? $arg-as ~~ any($plugin-lookup.keys)
                    ?? (for |$plugin-lookup{$arg-as} -> $p { $p<enabled> = $enabled })
                    !! @named.append($arg)
                !! @positional.append($arg);
        }
        $config;
    }


    sub get-client(*%_) {
        my $client   = Zef::Client.new(|%_);
        my $logger   = $client.logger;
        my $stdout   = $logger.Supply.grep({ .<level> <= $verbosity });
        my $reporter = $logger.Supply.grep({
                (.<stage> == TEST  && .<phase> == AFTER)
            ||  (.<level> == ERROR && .<phase> == AFTER)
            ||  (.<level> == FATAL && .<phase> == AFTER)
        });
        $stdout.tap: -> $m {
            given $m.<phase> {
                when BEFORE { say "===> {$m.<message>}" }
                when AFTER  { say "===> {$m.<message>}" }
                default     { print $m.<message> }
            }
        }
        $reporter.tap: -> $event {
            $client.reporter.report($event, :$logger);
        };

        $client;
    }

    # maybe its a name, maybe its a spec/path. either way  Zef::App methods take a CURs, not strings
    sub str2cur($target) {
        my $named-repo = CompUnit::RepositoryRegistry.repository-for-name($target);
        return $named-repo if $named-repo;

        # first try 'site', then try 'home'
        if $target eq 'auto' {
            state $cur =
                first { .can-install() },
                map   { CompUnit::RepositoryRegistry.repository-for-name($_) },
                <site home>;
            return $cur if $cur;
        }

        # Technically a path without any short-id# is a CURFS, but now it needs to be explicitly declared file#
        # so that the more common case can be used without the prefix (inst#). This only applies when the path
        # exists, so that short-names (site, home) that don't exist still throw errors instead of creating a directory.
        my $spec-target = $target ~~ m/^\w+\#.*?[\. | \/]/
            ?? $target
            !! $target.IO.e
                ?? "inst#{$target}"
                !! $target;

        return CompUnit::RepositoryRegistry.repository-for-spec(~$spec-target, :next-repo($*REPO));
    }

    sub path2candidate($path) {
        Candidate.new(
                as   => $path,
                uri  => $path.IO.absolute,
                dist => Zef::Distribution::Local.new($path),
        )
    }

    sub identity2spec($identity) {
        Zef::Distribution::DependencySpecification.new($identity);
    }

    # prints a table with rows and columns. expects a header row.
    # automatically adjusts column widths, as well as `yada`ing
    # any characters on a line past $max-width
    sub print-table(@rows, Int :$wrap) {
        # this ugly thing is so users can pass in Bool or Int as a MAIN argument
        my $max-width = ($*OUT.t && $wrap.perl eq 'Bool::False')
            ?? GET-TERM-COLUMNS()
            !! $wrap.perl eq 'Bool::True'
                ?? 0 
                !! $wrap;

        # returns formatted row
        my sub _row2str (@widths, @cells, Int :$max) {
            my $format = @widths.map({"%-{$_}s"}).join('|');
            my $str    = sprintf( $format, @cells.map({ $_ // '' }) );
            return $str unless ?$max && $str.chars > $max;

            my $cutoff = $str.substr(0, $max || $str.chars);
            return $cutoff unless $cutoff.chars > 3;
            return ($cutoff.substr(0,*-3) ~ '...') if $cutoff.substr(*-3,3) ~~ /\S\S\S/;
            return ($cutoff.substr(0,*-2) ~ '..')  if $cutoff.substr(*-2,2) ~~ /\S\S/;
            return ($cutoff.substr(0,*-1) ~ '.')   if $cutoff.substr(*-1,1) ~~ /\S/;
            return $cutoff;

        }

        # Iterate over ([1,2,3],[2,3,4,5],[33,4,3,2]) to find the longest string in each column
        my sub _get_column_widths ( *@rows ) is export {
            return @rows[0].keys.map: { @rows>>[$_]>>.chars.max }
        }

        my @widths     = _get_column_widths(@rows);
        my @fixed-rows = @rows.map: { _row2str(@widths, @$_, :max($max-width)) }
        if +@fixed-rows {
            my $width = [+] _get_column_widths(@fixed-rows);
            my $sep   = '-' x $width;
            say "{$sep}\n{@fixed-rows[0]}\n{$sep}";
            .say for @fixed-rows[1..*];
            say $sep;
        }
    }
}
