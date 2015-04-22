class Zef::App;

#core modes 
use Zef::Authority;
use Zef::Builder;
use Zef::Config;
use Zef::Depends;
use Zef::Getter;
use Zef::Installer;
use Zef::Reporter;
use Zef::Tester;
use Zef::Uninstaller;

use JSON::Fast;

# load plugins from config file
BEGIN our @plugins := %config<plugins>.list;

# when invoked as a class, we have the usual @.plugins
has @.plugins;

# override config file plugins if invoked as a class
# *and* :@plugins was passed to initializer 
submethod BUILD(:@!plugins) { 
@plugins := @!plugins if @!plugins.defined;
}



#| Test modules in cwd
multi MAIN('test') is export { &MAIN('test', |('test/', 'tests/', 't/', 'xt/')) }
#| Test modules in the specified directories
multi MAIN('test', *@paths) is export {
my $tester = Zef::Tester.new(:@plugins);
$tester.test($_) for @paths;
}

#| Install with business logic
multi MAIN('install', *@modules, Bool :$doinstall = True) is export {
"Fetching: {@modules.join(', ')}".say;
@modules.perl.say;
my %result = &MAIN('get', @modules);

#resolve dependencies
my @failures;
for %result.keys -> $k {
    my ($j, $i, @metas) = ('', 0, qw<META.info META6.info META.json META6.json>);
    @metas.perl.say;
    while $j.IO !~~ :f && @metas.elems > $i {
        CATCH { default { .resume; } }
        $j = $*SPEC.catpath('', %result{$k}, @metas[$i++]);
        $j.perl.say;
    }
    @failures.push($k), next if $i >= @metas.elems;
    $j = try from-json($j.IO.slurp);
    @failures.push($k), next if !($j<provides>:exists);
    next if !($j<depends>:exists);
    try { 
        if $j<depends> ~~ Array {
            &MAIN('install', @($j<depends>), :doinstall(False));  
        } else {
            &MAIN('install', $j<depends>.keys, :doinstall(False));
        }
        CATCH { default { warn $_; "CAUGHT $k".say; @failures.push($k => $_); } }
    };

}


for %result.keys -> $k {
    "Skipping $k due to depends failures".say, next if any(@failures.map({ "{$_ eq $k}".say; $_ eq $k }));
    if %result{$k} ~~ Str {
        my $build = &MAIN('build', %result{$k});
        $build.perl.say;
    } else {
        say "Error retrieving module: $k"; 
    }
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
@modules.perl.say;
my $getter = Zef::Getter.new(:@plugins);
$getter.get(:$save-to, |@modules);
}


#| Build modules in cwd
multi MAIN('build') is export { &MAIN('build', $*CWD) }
#| Build modules in the specified directories
multi MAIN('build', $path) {
my $builder = Zef::Builder.new(:@plugins);
$builder.pre-compile($path);
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
    say @term-results.hash.<reason> and next if @term-results.hash.<failure>;
    say "Results for $term";
    say "Package\tAuthor\tVersion";
    for @term-results -> %result {
        say "{%result<name>}\t{%result<owner>}\t{%result<version>}";
    }
}

exit(7) if [] ~~ all(%results.values);
}

multi MAIN('push', *@targets, Str :$session-key = %config<session-key>, :@exclude? = (/'.git'/,/'.gitignore'/), Bool :$force?) {
@targets.push($*CWD.Str) unless @targets.elems;
my $auth = Zef::Authority.new;
$auth.push(@targets, :$session-key, :@exclude, :$force) or { $*ERR.say; exit(7); }();
}
