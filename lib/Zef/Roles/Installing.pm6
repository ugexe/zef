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
    my $curlis = $curli-paths.list.map: -> $dir { CompUnitRepo::Local::Installation.new($dir) }

    method install(Bool :$force)  {
        my $i = eager gather for $curlis.list -> $curli is copy {
            mkdirs(PARSE-INCLUDE-SPEC($curli.Str).[*-1]) unless $curli.IO.e;
            $curli does curli-copy-fix[$.path];

            my %result      = %($.metainfo);
            %result<module> = $.name;
            %result<file>   = $.meta-path;
            %result<ok>     = 0;

            if !$force && !$.wanted {
                %result<skipped> = $.name;
                %result<ok> = 1;
                take %result;
                next;
            }

            my @bins      = $.path.child('bin').ls(:f, :r).grep(!*.starts-with('.'))>>.IO>>.relative($.path);
            my @provides  = $.provides.values.list;
            my @precomps  = self.?provides-precomp.values.list;
            my @files     = (@bins, @provides, @precomps).grep(*.so).list;

            %result<ok> = 1 if $curli.install(:dist(self), @files);
            take %result;
        }
        $i.list;
    }
}