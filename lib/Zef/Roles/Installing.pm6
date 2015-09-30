use Zef::Utils::PathTools;

role curli-fix[$path] {
    my $cp;
    ENTER {
        $cp = &copy.wrap({
            nextsame if $^a.IO.is-absolute;
            callwith($^a.IO.absolute($path), $^b);
        });
    }

    method get-dists {
        my $manifest := $.IO.child("MANIFEST");
        my $abspath  := $.IO.abspath;
        my %dists = $manifest.e
          ?? from-json($manifest.slurp)
          !! {};
    }
}

role Zef::Roles::Installing[$curli-paths = %*CUSTOM_LIB<site>] {
    my $curlis = $curli-paths.cache.map: -> $dir { CompUnitRepo::Local::Installation.new($dir) }

    method install(Bool :$force = False)  {
        my @installed;
        for $curlis.cache -> $curli is copy {
            mkdirs(PARSE-INCLUDE-SPEC($curli.Str).[*-1]) unless $curli.IO.e;
            $curli does curli-fix[$.path];

            my %result       = %($.metainfo);
            %result<unit-id> = $.name;
            %result<file>    = $.meta-path;
            %result<ok>      = 0;

            if !$force && !$.wanted {
                %result<skipped> = $.name;
                %result<ok>      = 1;
                @installed.push: $%result;
                next;
            }

            my @provides = $.provides.values;
            my @precomps = self.?provides-precomp.values;
            my @bins     = $.path.child('bin').ls(:f, :r)\
                .grep(!*.starts-with('.'))\
                .map: {.IO.relative($.path)}
            my @files    = flat (@provides, @precomps, @bins).grep(*.so);

            %result<ok> = 1 if $curli.install(:dist(self), |@files);
            @installed.push: $%result;
        }
        @installed;
    }
}
