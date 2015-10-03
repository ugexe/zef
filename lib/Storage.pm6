use Zef::Distribution::Local;

class Storage::GitRepo {
    has $.path;
    has $.source-uri;

    method new(Storage::GitRepo:U: $source-uri, :$path is copy = $*CWD) {
        $path = $path.IO.child($source-uri.IO.basename.subst(/'.git'$/, ''));
        my $r;
        if !$path.IO.child('.git').d {
            mkdir($path) unless $path.IO.d;
            $r = git-clone($source-uri, $path);
        }
        else {
            $r = git-status($path) || git-pull($source-uri, $path);
        }

        die "git commands failed" unless $r;
        self.bless(:$source-uri, :$path)
    }

    method spec { rx/'git://' | 'git@' | ['https://' .* '.git']/ }

    # this should be a Proxy
    method dist  { Zef::Distribution::Local.new( :$.path, :meta-path(self.meta-path) ) }
    method files { git-ls($.path) }

    #method files(*@_) { (@_ | $.path)>>.&ls }
    method meta  { state $json = try { from-json(self.meta-path.IO.slurp) } }
    method meta-path { state $file = self.files.first(*.IO.basename.lc eq 'meta6.json').IO }

    sub ls($p) { $p.IO.f ?? $p !! $p.IO.dir>>.&?ROUTINE }

    sub git-shell($cmd, $cwd) {
        my $s = shell(qq|git $cmd 2>&1|, :$cwd, :out);
        my @lines = $s.out.lines.eager;
        $s.out.close;
        $s.exitcode == 0 ?? (@lines || True) !! False;
    }
    sub git-clone($repo, $cwd) { git-shell(qq|clone $repo $cwd|, $cwd.IO.parent) }
    sub git-pull($cwd)         { git-shell(qq|pull|, $cwd)        }
    sub git-ls($cwd)           { git-shell(qq|ls-files|, $cwd)    }
    sub git-status($cwd)       { git-shell(qq|status -uno|, $cwd) }
}

class Storage {
    has @.rms; # reccomendation managers?
    has @.specs;

    method new(:@specs, *@all) {
        @specs.append: 'Storage::GitRepo'; # a default
        my @rms;
        for @all -> $str {
            @rms.append($_) for @specs\
                .grep({ my $rx = ::("$_").spec; $str ~~ $rx })\
                .grep({ state %c; not %c{$_.^name}++ })\ # remove duplicates
                .map({ ::("$_").new($str) })\
                .grep(*.so);
        }
        self.bless(:@rms, :@specs);
    }
}

