use Zef::Utils::PathTools;

class Zef::Installer {
    method install(:$save-to = %*CUSTOM_LIB<site>, *@metafiles, *%options) is export {
        mkdirs($save-to);
        my $curli := CompUnitRepo::Local::Installation.new($save-to);

        my @results = eager gather for @metafiles -> $meta-path {
            my Distribution $dist .= new( |from-json($meta-path.IO.slurp) ) does role { method metainfo {self.hash} };
            my %result = %(module => $dist.name, file => $meta-path, $dist.hash.flat); 
            %result<ok> = 0;

            # todo: pass all @curli locations instead of just a single $curli
            my @installed-at = IS-INSTALLED($dist, $curli);
            if @installed-at && !%options<force> {
                take %result<skipped> = @installed-at;
                next;
            }

            my @pm = $dist.provides.values.map({ $*SPEC.catpath('', $meta-path.IO.dirname, $_) })>>.IO;
            my @precomp = $meta-path.IO.dirname.IO.ls(:r, :f).grep({ $_.ends-with($*VM.precomp-ext) })>>.IO;

            %result<ok> = 1 if try $curli.install(:$dist, @pm, @precomp);
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
            say $curli.perl;
            take $curli;
        }
    }

    @installed;
}