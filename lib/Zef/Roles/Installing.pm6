use Zef::Utils::PathTools;

role Zef::Roles::Installing {
    has $!site = %*CUSTOM_LIB<site>;

    sub IS-INSTALLED($dist, *@curlis) {
        my $want-n = $dist.<name> or fail "A distribution must have a name";
        my $want-a = $dist.<auth>;
        my $want-v = Version.new($dist.<version> || '*').Str;

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

    method install(Bool :$force = True) is export {
        ENTER { mkdirs($!site) unless $!site.IO.d }
        my $curli := CompUnitRepo::Local::Installation.new($!site);

        my %result = %(module => $.name, file => $.meta-path, $.metainfo.flat); 
        %result<ok> = 0;

        # todo: pass all @curli locations instead of just a single $curli
        my @installed-at = IS-INSTALLED($.metainfo, $curli);
        if @installed-at && !$force {
            %result<skipped> = @installed-at;
            return %result;
        }

        # todo: just do this ourselfs, as unfortunately the path check for bin/ files
        # is just a regex against a relative path. This leaves no sane way to handle this 
        # without just implementing our own CURLI
        my @bins; # = $meta-path.IO.dirname.IO.child('bin').ls(:f).map({ "bin/{$_.IO.basename}" });

        my @provides = $.provides(:absolute).values;

        # Currently we need to send absolute paths to .install, but we use the relative path
        # still for discovering the correct file (hopefully)
        my @provides-precomps = %.meta<provides>.values.map({ "{$_}.{$*VM.precomp-ext}"});
        my @precomp = $.precomp-path.IO.ls(:r, :f)\
            .grep({ $_.ends-with(any(@provides-precomps)) })\
            .map({ $_.IO.absolute($.path) });

        %result<ok> = 1 if try $curli.install(dist => self, @provides, @precomp, @bins);
        return %result;
    }
}