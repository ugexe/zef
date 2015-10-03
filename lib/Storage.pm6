use Zef::Distribution::Local;

# Transparent storage access for CompUnitRepos

# Attempt to mimic CUR; Something like:
#   [Distribution <-> Storage::GitRepo]
#   [Distribution <\                  ]
#   [Distribution <-> Storage::CPAN   ]
#          ↑              ∨ ∧
#          ∟---------> [Storage] <= :@storages #`my @storages = <Storage::GitRepo Storage::CPAN Storage::CloudPAN>`
#                         ∨ ∧
#[get: Distribution.content][request: CompUnitRepo.candidates] < # *like* candidates but would return identities not CU
#                     [CompUnitRepo]                             # so the real .candidates would use it to search Storage
#                                                                # and Storage can transparently handle things like
#                                                                # search/fetch/update *if* you load such a Storage

class Storage::GitRepo {
    has $.path;
    has $.source-uri;

    my Regex $remote-spec  = rx/'git://' | 'git@' | ['https://' .* '.git']/;
    my Regex $local-spec   = rx/(.*){return False unless ?$0; my $g = $0.Str.IO.child(".git"); return ($g.IO.e && $g.IO.d)}/;

    proto method new(|) {*}
    multi method new(Storage::GitRepo:U: $path is copy, $source-uri?) {
        md($path);

        # If a $source-uri is passed in then we will assume the user *wants* to update-or-create.
        # Otherwise the user may pass in just the $path of a local repo with no $source-uri.
        if ?$source-uri {
            die "{$source-uri.perl} <- \$source-uri does not appear to be a git repo?" unless $source-uri ~~ $remote-spec;
            $path = $path.IO.child($source-uri.IO.basename.subst(/'.git'$/, ''));
            my $git-result = !$path.IO.child('.git').d
                ?? git-clone($source-uri, $path)
                !! (git-status($path) || git-pull($source-uri, $path));
            die "git commands failed" unless ?$git-result;
        }

        self.bless(:$path, :$source-uri);
    }
    multi method new(Storage::GitRepo:U: $source-uri where * ~~ $remote-spec) {
        callwith($*TMPDIR.child('p6repo'), $source-uri);
    }

    method spec { any($remote-spec, $local-spec) }

    # this should be a Proxy
    method dist  { Zef::Distribution::Local.new( :$.path, :meta-path(self.meta-path) ) }
    method files { git-ls($.path) }

    #method files(*@_) { (@_ | $.path)>>.&ls }
    method meta  { state $json = try { from-json(self.meta-path.IO.slurp) } }
    method meta-path { state $file = self.files.first(*.IO.basename.lc eq 'meta6.json').IO }

    sub ls($p) { $p.IO.f ?? $p !! $p.IO.dir>>.&?ROUTINE }
    sub md($p) is export { &?ROUTINE($p.IO.dirname) unless $p.IO.dirname.IO.e; mkdir($p) }

    sub git-shell($cmd, $cwd) {
        my $s = shell(qq|git $cmd 2>&1|, :$cwd, :out);
        my @lines = $s.out.lines.eager andthen $s.out.close;
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

