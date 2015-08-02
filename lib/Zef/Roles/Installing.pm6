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
    multi method install(Bool :$force)  {
        eager gather for $curlis.list -> $curli is copy {
            mkdirs(PARSE-INCLUDE-SPEC($curli).[*-1]) unless $curli.IO.e;

            $curli = CompUnitRepo::Local::Installation.new($curli);
            $curli does curli-copy-fix[$.path];

            my %result = %(module => $.name, file => $.meta-path, $.metainfo.flat); 
            %result<ok> = 0;

            # we could let CURLI handle this, but .install only tells us true/false
            my @installed-at = $.is-installed;
            if @installed-at && !$force {
                %result<skipped> = @installed-at;
                %result<ok> = 1;
                take { %result }
                next;
            }

            my @bins = $.path.child('bin').ls(:f, :r).grep(!*.starts-with('.'))>>.IO>>.relative($.path);
            my @provides = $.provides.values;
            my @precomps = self.?provides-precomp.values;

            %result<ok> = 1 if $curli.install(dist => self, @provides, @precomps, @bins);
            take { %result }
        }
    }
}