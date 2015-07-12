use Zef::Utils::PathTools;

class Zef::Installer {
    has $.force is rw;

    method install(:$save-to = %*CUSTOM_LIB<site>, *@metafiles, Bool :$force = True) is export {
        mkdirs($save-to);
        my $curli := CompUnitRepo::Local::Installation.new($save-to);

        my @results = eager gather for @metafiles -> $meta-path {
            my Distribution $dist .= new( |from-json($meta-path.IO.slurp) ) does role { method metainfo {self.hash} };
            my %result = %(module => $dist.name, file => $meta-path, $dist.hash.flat); 
            %result<ok> = 0;

            # todo: pass all @curli locations instead of just a single $curli
            my @installed-at = IS-INSTALLED($dist, $curli);
            if @installed-at && !$force {
                %result<skipped> = @installed-at;
                take { %result }
                next;
            }

            # this fakes a relative path for:
            # https://github.com/rakudo/rakudo/blob/nom/src/core/CompUnitRepo/Local/Installation.pm#L115
            # Note that depending on $*CWD the copy at the end of method install may fail. todo: fix
            my @bins = $meta-path.IO.dirname.IO.child('bin').ls(:f).map({ "bin/{$_.IO.basename}" });

            my @provides = $dist.provides.values.map({ $_.IO.absolute($meta-path.IO.dirname) });

            # Currently we need to send absolute paths to .install, but we use the relative path
            # still for discovering the correct file (hopefully)
            my @provides-precomps = $dist.provides.values.map({ "{$_}.{$*VM.precomp-ext}"});
            my @precomp = $meta-path.IO.dirname.IO.ls(:r, :f)\
                .grep({ $_.ends-with(any(@provides-precomps)) })\
                .map({ $_.IO.absolute($meta-path.IO.dirname) });

            %result<ok> = 1 if $curli.install(:$dist, @provides, @precomp, @bins);

            take { %result }
        }

        return @results;
    }
}

sub IS-INSTALLED(Distribution $dist, *@curlis) {
    my $want-n = $dist.name or fail "A distribution must have a name";
    my $want-a = $dist.auth || "{$dist.authority || ''}:{$dist.author || ''}";
    my $want-v = Version.new($dist.ver || $dist.version || '*').Str;

    my @installed = gather for @curlis -> $curli {
        CANDI:
        for $curli.candidates($want-n).list -> $have {
            my $have-n = $have<name> or next CANDI;
            my $have-a = $have<auth> || "{$have<authority> || ''}:{$have<author> || ''}";
            my $have-v = Version.new($have<ver> || $have<version> || '*').Str;
            next CANDI unless $have-n.lc eq $want-n.lc;
            next CANDI unless $have-a.lc eq $want-a.lc;
            next CANDI unless ($have-v.lc eq $want-v.lc || $want-v eq '*');
            take $curli;
        }
    }

    @installed;
}