use Zef::Config;
use Zef::Distribution::Local;
use Zef::Fetch;
use Zef::ContentStorage;
use Zef::Extract;
use Zef::Test;

our %CONFIG = ZEF-CONFIG();

class Zef::App {
    has $.cache;
    has $.indexer;
    has $.fetcher;
    has $.storage;
    has $.extractor;
    has $.tester;
    has @!ignore = <Test NativeCall lib MONKEY-TYPING nqp>;
    has $!lock = Lock.new;

    submethod BUILD(
        :$!cache     = "{%CONFIG<Store>}/store",
        :@fetchers   = |(%CONFIG<Fetch>),
        :@storages   = |(%CONFIG<ContentStorage>),
        :@extractors = |(%CONFIG<Extract>),
        :@testers    = |(%CONFIG<Test>),
    ) {
        mkdir $!cache unless $!cache.IO.e;
        $!fetcher   = Zef::Fetch.new( :backends(@fetchers) );
        $!storage   = Zef::ContentStorage.new( :backends(@storages), :$!fetcher, :$!cache );
        $!extractor = Zef::Extract.new( :backends(@extractors) );
        $!tester    = Zef::Test.new( :backends(@testers) );
    }

    method candidates(Bool :$depends, Bool :$test-depends, Bool :$build-depends,
                 Bool :$force, Bool :$verbose, Bool :$upgrade, *@wants) {

        my &stdout = ?$verbose ?? -> $o {$o.say} !! -> $ { };
        # Once metacpan can return results again this will need to be modified so as not to
        # duplicate an identity that shows up from multiple ContentStorages.
        # XXX: :$update means to *not* take the first matching candidate encountered, but
        # the highest version that matches from all available storages (break out of ::LocalCache)
        sub get-dists(*@_) {
            state %found;
            my @allowed = |@_.grep(* ~~ none(|@!ignore, |%found.keys)).unique || return;
            say "Searching for {'dependencies ' if state $once++}{@allowed.join(', ')}" if ?$verbose;
            ALLOWED:
            for @allowed -> $wanted {

                # todo: allow sorting `candidates` by version
                CONTENT:
                for $!storage.candidates($wanted, :$upgrade) -> $cs {
                    my $storage := $cs.key;
                    my $dist    := $cs.value[0];

                    unless %found{$wanted}:exists {
                        say "[$storage] found {$dist.name}" if ?$verbose;
                        %found{$wanted} := $cs;

                        # so the user can see if $wanted was discovered as dist or a module
                        $dist.metainfo<requested-as> = $wanted;

                        # todo: alternatives, i.e. not a Str but [Str, Str]
                        my @wanted-deps = unique(grep *.chars,
                            ($dist.depends       if ?$depends).Slip,
                            ($dist.test-depends  if ?$test-depends).Slip,
                            ($dist.build-depends if ?$build-depends).Slip);
                        get-dists(|@wanted-deps) if @wanted-deps.elems;
                        next ALLOWED;
                    }
                }
            }
            %found
        }

        my %found = get-dists(|@wants);

        if @wants.grep(* !~~ any(@!ignore)).grep({ not %found{$_}:exists }) -> @wanted {
            say "Could not find distributions matching {@wanted.join(',')}";
            die unless ?$force;
        }

        %found;
    }

    method fetch(Bool :$depends = True, Bool :$test-depends = True, Bool :$build-depends = True,
                 Bool :$force, Bool :$verbose, *@wants) {

        my %found = self.candidates(:$depends, :$test-depends, :$build-depends, :$force, :$verbose, |@wants);
        self!fetch(%found, :$depends, :$test-depends, :$build-depends, :$force, :$verbose)
    }
    method !fetch($storage, :$depends, :$test-depends, :$build-depends, Bool :$force, Bool :$verbose) {
        my &stdout = ?$verbose ?? -> $o {$o.say} !! -> $ { };

        gather for $storage.kv -> $requested-as, $cs {
            my $from = $cs.key;
            my $dist = $cs.value[0];
            my $sanitized-name = $dist.name.subst(':', '-', :g);
            my $uri = $dist.source-url;
            my $extract-to = $!cache.IO.child($sanitized-name);
            my $save-as    = $!cache.IO.child($uri.IO.basename);

            say "Fetching `{$requested-as}` as {$dist.identity}";

            # todo: abstract this away properly with either a specific file uri
            # fetcher, modifying the source-url field to a path, or create a cacher role
            if $from eq 'Zef::ContentStorage::LocalCache' {
                say "[$from] cached at $save-as" if ?$verbose;
            }
            else {
                $!fetcher.fetch($uri, $save-as, :&stdout);
                say "[$from] {$uri} --> $save-as" if ?$verbose;
            }

            # should probably break this out into its out method
            if $save-as.lc.ends-with('.tar.gz' | '.zip') {
                say "Extracting: {$save-as} to {$extract-to}" if ?$verbose;
                $save-as = $!extractor.extract($save-as, $extract-to);
            }

            $dist does Zef::Distribution::Local($save-as);
            $!storage.store($dist);

            take $dist;
        }
    }

    method test(Bool :$force, Bool :$verbose, :@includes, *@paths) {
        % = @paths.classify: -> $path {
            say "Start test phase for: $path";

            my &stdout = ?$verbose ?? -> $o {$o.say} !! -> $ { };

            my $result = try $!tester.test($path, :includes(@includes.grep(*.so)), :&stdout);

            if !$result {
                die "Aborting due to test failure at: {$path} (use :force to override)" unless ?$force;
                say "Test failure at: {$path}. Continuing anyway with :force"
            }
            else {
                say "Testing passed for {$path}";
            }

            # should really return a hash of passes and failures
            ?$result
        }
    }

    method search(*@identities, *%fields) {
        $!storage.search(|@identities, |%fields);
    }

    method install(:$install-to = ['site'], *@wants, *%_) {
        state @can-install-ids = $*REPO.repo-chain.unique( :as(*.id) )\
            .grep(*.?can-install)\
            .map({.id});

        my @target-curs = $install-to\
            .map({ ($_ ~~ CompUnit::Repository) ?? $_ !! CompUnit::RepositoryRegistry.repository-for-name($_) })\
            .grep(*.defined)\
            .grep({ .id ~~ any(@can-install-ids) });

        self!install(:@target-curs, |%_, |@wants);
    }

    method !install(:@target-curs, Bool :$force, Bool :$fetch, Bool :$test, Bool :$dry, Bool :$verbose,
                    Bool :$depends, Bool :$build-depends, Bool :$test-depends, Bool :$upgrade, *@wants, *%_) {

        my &notice = ?$force ?? &say !! &die;

        my @discovered = eager gather for @wants -> $want {
            if $want.starts-with('.' | '/') && $want.IO.e {
                my $dist = Zef::Distribution::Local.new($want.IO.absolute);

                my @deps = unique(grep *.defined,
                    ($dist.depends       if ?$depends).Slip,
                    ($dist.test-depends  if ?$test-depends).Slip,
                    ($dist.build-depends if ?$build-depends).Slip);

                if +@deps {
                    take $_ for |self.candidates(|@deps, :$depends, :$build-depends, :$test-depends, :$verbose, :$force, :$upgrade, |%_);
                }

                # local paths should probably just use LocalCache
                take ($want => ('IO::Path' => $dist));
            }
            else {
                take $_ for |self.candidates($want, :$depends, :$build-depends, :$test-depends, :$verbose, :$force, :$upgrade, |%_);
            }
        }


        my @dists = eager gather for @discovered -> $store {
            take $_ for |self!fetch($store, :$depends, :$build-depends, :$test-depends, :$verbose, :$force, |%_);
        }


        # todo: put this into its own subroutine or module. just a placeholder example for now
        my @filtered-dists = eager gather DIST: for @dists -> $dist {
            say "[DEBUG] Filtering {$dist.name}" if ?$verbose;
            if ?$dist.is-installed {
                my $reported-id = ?$verbose ?? $dist.identity !! $dist.name;
                unless ?$force {
                    say "{$reported-id} is already installed. Skipping... (use :force to override)";
                    next;
                }

                say "{$reported-id} is already installed. Continuing anyway with :force";
            }

            # Should `License` be a root option key?
            # If not, would it go under `Fetch` or `ContentStorage`? a new phase like `Filter`?
            given %CONFIG<License> {
                CATCH { default {
                    say $_.message;
                    die    "Allowed licenses: {%CONFIG<License>.<whitelist>.join(',')    || 'n/a'}\n"
                        ~  "Disallowed licenses: {%CONFIG<License>.<blacklist>.join(',') || 'n/a'}";
                } }
                when .<blacklist>.?chars && any(|.<blacklist>) ~~ any('*', $dist.license // '') {
                    notice "License blacklist configuration exists and matches {$dist.license // 'n/a'} for {$dist.name}";
                }
                when .<whitelist>.?chars && any(|.<whitelist>) ~~ none('*', $dist.license // '') {
                    notice "License whitelist configuration exists and does not match {$dist.license // 'n/a'} for {$dist.name}";
                }
            }

            take $dist;
        }

        my @sorted-dists = topological-sort(@filtered-dists, :$depends, :$build-depends, :$test-depends, |%_);

        # attach appropriate metadata so we can do --dry runs using -I/some/dep/path
        # and can install after we know they pass tests
        my @installable-dists = eager gather for @sorted-dists -> $dist {
            say "[DEBUG] Processing {$dist.name}" if ?$verbose;

            my @dep-specs = unique(grep *.defined,
                ($dist.depends-specs       if ?$depends).Slip,
                ($dist.test-depends-specs  if ?$test-depends).Slip,
                ($dist.build-depends-specs if ?$build-depends).Slip);

            # this could probably be done in the topological-sort itself
            $dist.metainfo<includes> = eager gather DEPSPEC: for @dep-specs -> $spec {
                for @filtered-dists -> $fd {
                    if $fd.contains-spec($spec) {
                        take $fd.IO.child('lib').absolute;
                        take $_ for |$fd.metainfo<includes>;
                        next DEPSPEC;
                    }
                }
            }

            notice "Build.pm hook failed" if $dist.IO.child('Build.pm').e && !legacy-hook($dist);

            take $dist if ?$test ?? self.test($dist.path, :includes(|$dist.metainfo<includes>), :$verbose, :force(?$force)) !! True;
        }

        for @installable-dists -> $dist {
            for @target-curs -> $cur {
                if ?$dry {
                    say "{$dist.name}#{$dist.path} processed successfully";
                }
                else {
                    #$!lock.protect({
                        say "Installing {$dist.name}#{$dist.path} to {$cur.short-id}#{~$cur}";
                        $cur.install($dist, $dist.sources(:absolute), $dist.scripts, $dist.resources, :force(?$force));
                    #});
                }
            }
        }

        # report phase
        unless $dry {
            if @installable-dists.flatmap(*.scripts.keys).unique -> @bins {
                say "\n{+@bins} bin/ script{+@bins>1??'s'!!''}{+@bins&&?$verbose??' ['~@bins~']'!!''} installed to:"
                ~   "\n\t" ~ @target-curs.map(*.prefix.child('bin')).join("\n");
            }
        }
    }
}

# simple topological sort
# todo: bring back the more advanced sort zef previously used, but use with Distribution objects
sub topological-sort(@dists, Bool :$depends = True, Bool :$build-depends = True, Bool :$test-depends = True, *%_) {
    my @tree;
    my $visit = sub ($dist, $from? = '') {
        return if ($dist.metainfo<marked> // 0) == 1;
        if ($dist.metainfo<marked> // 0) == 0 {
            $dist.metainfo<marked> = 1;

            my @deps = unique(grep *.defined,
                ($dist.depends-specs       if ?$depends).Slip,
                ($dist.test-depends-specs  if ?$test-depends).Slip,
                ($dist.build-depends-specs if ?$build-depends).Slip);

            for @deps -> $m {
                for @dists.grep(*.spec-matcher($m)) -> $m2 {
                    $visit($m2, $dist);
                }
            }
            @tree.append($dist);
        }
    };

    for @dists -> $dist {
        $visit($dist, 'olaf') if ($dist.metainfo<marked> // 0) == 0;
    }

    return @tree;
}

# todo: write a real hooking implementation to CU::R::I instead of the current practice
# of writing an installer specific (literally) Build.pm
sub legacy-hook($dist) {
    my $builder-path = $dist.IO.child('Build.pm');

    # if panda is declared as a dependency then there is no need to fix the code, although
    # it would still be wise for the author to change their code as outlined in $legacy-fixer-code
    unless $dist.depends.first(/'panda' | 'Panda::'/)
        || $dist.build-depends.first(/'panda' | 'Panda::'/)
        || $dist.test-depends.first(/'panda' | 'Panda::'/) {

        my $legacy-fixer-code = q:to/END_LEGACY_FIX/;
            class Build {
                method isa($what) {
                    return True if $what.^name eq 'Panda::Builder';
                    callsame;
                }
            END_LEGACY_FIX

        my $legacy-code = $builder-path.IO.slurp;
        $legacy-code.subst-mutate(/'use Panda::' \w+ ';'/, '', :g);
        $legacy-code.subst-mutate('class Build is Panda::Builder {', "{$legacy-fixer-code}\n");
        $builder-path = "{$builder-path.absolute}.zef".IO;
        try { $builder-path.spurt($legacy-code) } || $builder-path.subst-mutate(/'.zef'$/, '');
    }

    my $cmd = "require <{$builder-path.basename}>; ::('Build').new.build('{$dist.IO.absolute}') ?? exit(0) !! exit(1);";

    my $result;
    try {
        use Zef::Shell;
        CATCH { default { $result = False; } }
        my @includes = $dist.metainfo<includes>.map: { "-I{$_}" }
        my $proc = zrun($*EXECUTABLE, '-I.', '-Ilib', |@includes, '-e', "$cmd", :cwd($dist.path), :out, :err);
        .say for $proc.out.lines;
        .say for $proc.err.lines;
        $proc.out.close;
        $proc.err.close;
        $result = ?$proc;
    }
    $builder-path.IO.unlink if $builder-path.ends-with('.zef') && "{$builder-path}".IO.e;
    $ = $result;
}
