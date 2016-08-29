use Zef;
use Zef::Shell;
use Zef::Utils::FileSystem;

class Zef::Service::Shell::Build is Zef::Shell does Builder does Messenger {
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

    my $meta-path = first *.e, $path.IO.child('META6.json'), $path.IO.child('META.info');
    my %meta-hash = from-json($meta-path.slurp).hash;

    my $builder-path = $path.IO.child('Build.pm');
    my $legacy-code  = $builder-path.IO.slurp;

    # if panda is declared as a dependency then there is no need to fix the code, although
    # it would still be wise for the author to change their code as outlined in $legacy-fixer-code
    my $needs-panda = ?$legacy-code.contains('use Panda');
    my $reqs-panda  = ?%meta-hash<depends build-depends test-depends>.grep(*.so).flatmap(*.grep(/^[:i 'panda']/));

    if ?$needs-panda && !$reqs-panda {
        $stderr.emit("`build-depends` is missing entries. Attemping to workaround via source mangling...") if $DEBUG;

        my $legacy-fixer-code = q:to/END_LEGACY_FIX/;
            class Build {
                method isa($what) {
                    return True if $what.^name eq 'Panda::Builder';
                    callsame;
                }
            END_LEGACY_FIX

        $legacy-code.subst-mutate(/'use Panda::' \w+ ';'/, '', :g);
        $legacy-code.subst-mutate('class Build is Panda::Builder {', "{$legacy-fixer-code}\n");

        try {
            move "{$builder-path}", "{$builder-path}.bak";
            spurt "{$builder-path}", $legacy-code;
        }
    }

    # Rakudo bug related to using path instead of module name
    # my $cmd = "require <{$builder-path.basename}>; ::('Build').new.build('{$path.IO.absolute}'); exit(0);";
    my $cmd = "::('Build').new.build('{$path.IO.absolute}'); exit(0);";

    my $result;
    try {
        use Zef::Shell;
        CATCH { default { $result = False; } }

        # see: https://github.com/ugexe/zef/issues/93
        # my @exec = |($*EXECUTABLE, '-Ilib', '-I.', |@cl-includes, '-e', "$cmd");
        my @exec = |($*EXECUTABLE, '-Ilib', '-I.', '-MBuild', |@includes.grep(*.defined).map({ "-I{$_}" }), '-e', "$cmd");

        $stdout.emit("Command: {@exec.join(' ')}") if $DEBUG;

        my $proc = zrun(|@exec, :cwd($path), :out, :err);

        # Build phase can freeze up based on the order of these 2 assignments
        # This is a rakudo bug with an unknown cause, so may still occur based on the process's output
        my @out = $proc.out.lines;
        my @err = $proc.err.lines;

        $ = $proc.out.close unless +@err;
        $ = $proc.err.close;
        $result = ?$proc;

        $stdout.emit(@out.join("\n")) if +@out;
        $stderr.emit(@err.join("\n")) if +@err;
    }

    if my $bak = "{$builder-path}.bak" and $bak.IO.e {
        try {
            unlink $builder-path;
            move $bak, $builder-path;
        } if $bak.IO.f;
    }

    $ = ?$result;
}
