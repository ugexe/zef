unit class Zef::App;

#core modes 
use Zef::Authority;
use Zef::Builder;
use Zef::Config;
use Zef::Getter;
use Zef::Installer;
use Zef::Reporter;
use Zef::Tester;
use Zef::Uninstaller;
use Zef::Utils::PathTools;

# load plugins from config file
BEGIN our @plugins := %config<plugins>.list;

# when invoked as a class, we have the usual @.plugins
has @!plugins;

# override config file plugins if invoked as a class
# *and* :@plugins was passed to initializer 
submethod BUILD(:@!plugins) { 
    @plugins := @!plugins if @!plugins.defined;
}


#| Test modules in the specified directories
multi MAIN('test', *@paths) is export {
    @paths = $*CWD unless @paths;
    my $tester  = Zef::Tester.new(:@plugins);
    my @results = $tester.test(@paths);
    my $failures = @results.grep({ !$_.<ok>  }).elems;
    say "-" x 42;
    say "Total  test files: {@results.elems}";
    say "Passed test files: {@results.elems - $failures}";
    say "Failed test files: $failures";
    say "-" x 42;
    exit $failures;
}


multi MAIN('install', :$p6c where True, *@modules) is export {
    my @installed = gather for @modules -> $module-name {
        my $g = Zef::Getter.new( plugins => ["Zef::Plugin::P6C"] ); 
        my @r = $g.get($module-name);
        my @b = Zef::Builder.new.pre-compile( @r.map({ $_.<path> }) );
        my @t = Zef::Tester.new.test(@b.map({ $*SPEC.catdir($_.<path>) }));
        say "Testing failed" and exit 1 if @t.grep({ !$_.<ok>  });
        my @i = Zef::Installer.new.install(@b.map({ $*SPEC.catpath("", $_.<path>, "META.info") }));
        take $module-name unless @i.grep({ !$_.<ok> });
    }
    exit @modules.elems - @installed.elems;
}

#| Install with business logic
multi MAIN('install', *@modules, Bool :$doinstall = True) is export {
    "Fetching: {@modules.join(', ')}".say;
    my @failures;
    my $save-to = $*SPEC.catdir($*CWD, time).IO;
    mkdirs($save-to);

    for @modules -> $module {
        my @repo      = &MAIN('get', :$save-to, $module);
        my $meta-file = @repo.grep({ $_.<path>.IO.basename ~~ any(<META.info META6.json>) }).[0] or next;
        my %meta      = %(from-json($meta-file.<path>.IO.slurp));
        my @depends   = %meta.<depends>.list;

        for @depends -> $dep {
            &MAIN('install', $dep, :doinstall(False));
        }

        &MAIN('build', $module);
    }

}


#| Install local freshness
multi MAIN('local-install', *@modules) is export {
    my $installer = Zef::Installer.new(:@plugins);
    $installer.install($_) for @modules;
}


#| Get the freshness
multi MAIN('get', :$save-to = "$*CWD/{time}", *@modules) is export {
    # {time} can be removed when we fetch actual versioned archives
    # so we dont accidently overwrite files in $*CWD
    my $getter = Zef::Getter.new(:@plugins);
    my @results = $getter.get(:$save-to, |@modules);
    return @results;
}


#| Build modules in cwd
multi MAIN('build') is export { &MAIN('build', $*CWD) }
#| Build modules in the specified directories
multi MAIN('build', $path, :$save-to) {
    my $builder = Zef::Builder.new(:@plugins);
    $builder.pre-compile($path, :$save-to);
}

multi MAIN('login', Str $username, Str $password? is copy) {
    $password //= prompt 'Password: ';
    say "Password required" && exit(1) unless $password;
    my $auth = Zef::Authority.new;
    $auth.login(:$username, :$password) or { $*ERR.say; exit(2) }();
    %config<session-key> = $auth.session-key // exit(3);
    save-config;
}

multi MAIN('register', Str $username, Str $password? is copy) {
    $password //= prompt 'Password: ';
    say "Password required" && exit(1) unless $password;
    my $auth = Zef::Authority.new;
    $auth.register(:$username, :$password) or { $*ERR.say; exit(5) }();
    %config<session-key> = $auth.session-key or exit(6);
    save-config;
}

multi MAIN('search', *@terms) {
    my $auth = Zef::Authority.new;
    my %results = $auth.search(@terms) or exit(4);
    for %results.kv -> $term, @term-results {
        say "No results for $term" and next unless @term-results;
        try say @term-results.hash.<reason> and next if @term-results.hash.<failure>;
        say "Results for $term";
        say "Package\tAuthor\tVersion";
        for @term-results -> %result {
            say "{%result<name>}\t{%result<owner>}\t{%result<version>}";
        }
    }

    exit(7) if [] ~~ all(%results.values);
}

multi MAIN('push', *@targets, Str :$session-key = %config<session-key>, :@exclude? = (/'.git'/,/'.gitignore'/), Bool :$force?) {
    @targets.push($*CWD.IO.path) unless @targets.elems;
    my $auth = Zef::Authority.new;
    $auth.push(@targets, :$session-key, :@exclude, :$force) or { $*ERR.say; exit(7); }();
}
