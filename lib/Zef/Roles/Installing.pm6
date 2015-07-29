use Zef::Utils::PathTools;

role curli-copy-fix[$path] {
    my $cp;
    ENTER {
        $cp = &copy.wrap({
            nextsame if $^a.IO.is-absolute;
            callwith($^a.IO.absolute($path), $^b);
        });
    }
}

role Zef::Roles::Installing[$curlis = %*CUSTOM_LIB<site>] {
    multi method install(Bool :$force = True)  {
        eager gather for $curlis.list -> $curli is copy {
            mkdirs(PARSE-INCLUDE-SPEC($curli).[*-1]) unless $curli.IO.e;

            $curli = CompUnitRepo::Local::Installation.new($curli);
            $curli does curli-copy-fix[$.path];

            my %result = %(module => $.name, file => $.meta-path, $.metainfo.flat); 
            %result<ok> = 0;

            # todo: pass all @curli locations instead of just a single $curli
            my @installed-at = IS-INSTALLED($.metainfo, $curli);
            if @installed-at && !$force {
                %result<skipped> = @installed-at;
                take %result;
                next;
            }

            # todo: just do this ourselfs, as unfortunately the path check for bin/ files
            # is just a regex against a relative path. This leaves no sane way to handle this 
            # without just implementing our own CURLI
            my @bins = $.path.child('bin').ls(:f, :r).grep(!*.starts-with('.'))>>.IO>>.relative($.path);

            my @provides = $.provides.values;

            # Currently we need to send absolute paths to .install, but we use the relative path
            # still for discovering the correct file (hopefully)
            my @precomps = self.?provides-precomps().values;

            %result<ok> = 1 if $curli.install(dist => self, @provides, @precomps, @bins);
            take { %result }
        }
    }


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
}