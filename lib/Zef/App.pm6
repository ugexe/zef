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

    method fetch(Bool :$depends = True, Bool :$test-depends = True, Bool :$build-depends = True,
                 Bool :$force, Bool :$verbose, *@wants) {

        my &stdout = ?$verbose ?? -> $o {$o.say} !! -> $ { };
        # Once metacpan can return results again this will need to be modified so as not to
        # duplicate an identity that shows up from multiple ContentStorages
        #
        # todo: Update ContentStorage::CPAN to use Distribution.name/etc instead of %meta<name>/<etc>
        sub get-dists(*@_) {
            state %found;
            my @allowed = |@_.grep(* ~~ none(|@!ignore, |%found.keys)).unique || return;
            say "Searching for {'dependencies ' if state $once++}{@allowed.join(', ')}" if ?$verbose;
            ALLOWED:
            for @allowed -> $wanted {
                CONTENT:
                for $!storage.candidates($wanted) -> $cs {
                    my $storage = $cs.key;
                    my $dist    = $cs.value[0];
                    unless %found{$wanted}:exists {
                        %found{$wanted} = $dist;
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

        if @wants.grep({ not %found{$_}:exists }) -> $wanted {
            say "Could not find distributions matching {$wanted.join(',')}";
            die unless ?$force;
        }

        gather for %found.values -> $dist {
            my $sanitized-name = $dist.name.subst(':', '-', :g);
            my $uri = $dist.source-url;
            my $extract-to = $!cache.IO.child($sanitized-name);
            my $save-as    = $!cache.IO.child($uri.IO.basename);

            say "Fetching {$dist.identity}#{$uri}{?$verbose ?? qq| to $save-as| !! ''}";
            $!fetcher.fetch($uri, $save-as, :&stdout);
            
            # should probably break this out into its out method
            if $save-as.lc.ends-with('.tar.gz' | '.zip') {
                say "Extracting: {$save-as} to {$extract-to}" if ?$verbose;
                $save-as = $!extractor.extract($save-as, $extract-to);
            }

            $dist does Zef::Distribution::Local($save-as);
            take $dist;
        }
    }

    method test(Bool :$force, Bool :$verbose, :@includes, *@paths) {
        % = @paths.classify: -> $path {
            say "Start test phase for: $path";

            my &stdout = ?$verbose ?? -> $o {$o.say} !! -> $ { };

            my $result = $!tester.test($path, :includes(@includes.grep(*.so)), :&stdout);

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
                    Bool :$depends, Bool :$build-depends, Bool :$test-depends, *@wants, *%_) {

        my &notice = ?$force ?? &say !! &die;

        my @dists = eager gather for @wants -> $want {
            # todo: manifest/lookup for ContentStorage.cache + Fetcher for local paths (for .fetch("some-path", :depends))
            # 1) Will allow checking path for meta info to see if we can skip fetching it
            # 2) @wants may contain an identity but also a path string. However, if dependencies
            # are needed they will always be identities so this would let us translate those
            # identities into local paths (if they exist) to take any required actions on
            given $want {
                when /^<[./]>/ && .IO.e {
                    take Zef::Distribution::Local.new($_.IO.absolute);
                }
                when ?$fetch {
                    take $_ for |self.fetch($_, :$depends, :$build-depends, :$test-depends, :$verbose, |%_);
                }
                default {
                    notice "Don't know how to locate '$want'. Did you mean to pass :fetch?";
                }

            }
        }

        # todo: put this into its own subroutine or module. just a placeholder example for now
        my @filtered-dists = eager gather DIST: for @dists -> $dist {
            say "[DEBUG] Filtering {$dist.name}" if ?$verbose;
            # todo: handle this lazily or in a way where we don't fetch stuf we already have
            if $dist.name ne 'Zef' && ?$dist.is-installed && $dist.IO !~~ $*CWD {
                unless ?$force {
                    say "{$dist.name} is already installed. Skipping... (use :force to override)";
                    next;
                }
                say "{$dist.name} is already installed. Continuing anyway with :force";
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
                        # not sure if we can use an absolute file path on windows for -I
                        # so may need to use PERL6LIB instead of -I. This might also
                        # solve any possible "command over length limit" that might
                        # otherwise be reached for a large depenency chain
                        take $fd.path.IO.child('lib').absolute;
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
    my $builder-path = $dist.path.IO.child('Build.pm');

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

    my $cmd = "require <{$builder-path.basename}>; ::('Build').new.build('{$dist.path.IO.absolute}') ?? exit(0) !! exit(1);";

    my $result;
    try {
        CATCH { default { $result = False; } }
        my @includes = $dist.metainfo<includes>.map: { "-I{$_}" }
        my $proc = run($*EXECUTABLE, '-I.', '-Ilib', |@includes, '-e', "$cmd", :cwd($dist.path), :out, :err);
        .say for $proc.out.lines;
        .say for $proc.err.lines;
        $proc.out.close;
        $proc.err.close;
        $result = ?$proc;
    }
    $builder-path.IO.unlink if $builder-path.ends-with('.zef') && "{$builder-path}".IO.e;
    $ = $result;
}
