use Zef;
use Zef::Utils::FileSystem;

class Zef::Service::Shell::Build does Builder does Messenger {
    method build-matcher($path) { $path.IO.child("Build.pm").e }

    method probe { True }

    # todo: write a real hooking implementation to CU::R::I
    # this is a giant ball of shit btw, but required for
    # all the existing distributions using Build.pm
    method build($path, :@includes) {
        die "path does not exist: {$path}" unless $path.IO.e;
        my $build-file = list-paths($path, :!r, :f, :!d).first({.basename eq 'Build.pm'});

        my $json-ext = $path.IO.child('META6.json').e;
        my Str $comp-version = ~$*PERL.compiler.version;
        my $meta-name-workaround = $comp-version.substr(5..6) <= 5
                                && $comp-version.substr(0..3) <= 2016
                                && $json-ext;

        my $orig-result = legacy-build($path, :@includes, :$.stderr, :$.stdout);
        return $orig-result if ?$orig-result;

        # Workaround rakudo CUR::FS bug when distribution has a
        # Build.pm file, is using META6.json (not META.info), and
        # the rakudo version is < 2016.05
        # Retries try-legacy-hook after adding 'Build' => 'Build.pm' to provides
        if $meta-name-workaround {
            my $meta6-path     = $path.IO.child('META6.json');
            my $meta6-bak      = $meta6-path.absolute ~ '.bak';
            my $meta6-contents = $meta6-path.IO.slurp;
            try move $meta6-path, $meta6-bak;
            my %meta6 = from-json($meta6-contents);
            %meta6<provides><Build> = 'Build.pm';
            "{$meta6-path}".IO.spurt( to-json(%meta6) );
            my $result = legacy-build($path, :@includes, :$.stderr, :$.stdout);
            try unlink $meta6-path;
            try move $meta6-bak, $meta6-path;
            $result;
        }
    }
}

my sub legacy-build($path, :@includes, :$stderr, :$stdout) {
    my $DEBUG = ?%*ENV<ZEF_BUILDPM_DEBUG>;

    # Rakudo bug related to using path instead of module name
    # my $cmd = "require <{$builder-path.basename}>; ::('Build').new.build('{$path.IO.absolute}'); exit(0);";
    my $cmd = "::('Build').new.build('{$path.IO.absolute}'); exit(0);";

    # see: https://github.com/ugexe/zef/issues/93
    # my @exec = |($*EXECUTABLE, '-Ilib', '-I.', |@cl-includes, '-e', "$cmd");
    my @exec = |($*EXECUTABLE, '-Ilib', '-I.', '-MBuild', |@includes.grep(*.defined).map({ "-I{$_}" }), '-e', "$cmd");

    $stdout.emit("Command: {@exec.join(' ')}") if $DEBUG;

    my $ENV := %*ENV;
    my $passed;
    react {
        my $proc = zrun-async(@exec);
        whenever $proc.stdout { $stdout.emit($_.chomp) }
        whenever $proc.stderr { $stderr.emit($_.chomp) }
        whenever $proc.start(:$ENV, :cwd($path)) { $passed = $_.so }
    }
    return $passed;
}
