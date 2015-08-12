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

role Zef::Roles::Installing[$curli-paths = %*CUSTOM_LIB<site>] {
    my @curlis    = CompUnitRepo::Local::Installation.new($_) for $curli-paths.list;

    method install(Bool :$force)  {
        eager gather for @curlis -> $curli is copy {
            mkdirs(PARSE-INCLUDE-SPEC($curli.Str).[*-1]) unless $curli.IO.e;
            $curli does curli-copy-fix[$.path];

            my %result = %(module => $.name, file => $.meta-path, $.metainfo.flat); 
            %result<ok> = 0;

            if !$force && !$.wanted {
                %result<skipped> = $.name;
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