use Zef::Distribution;

role Zef::Distribution::Local {
    has $.path;
    has $!IO;

    method new($path) {
        my $meta-path = self.find-meta($path) // die "No meta file? Path: {$path}";
        my $json      = try { from-json($meta-path.IO.slurp) } || die "Invalid json? {$meta-path}";
        my %meta      = %($json);
        $ = Zef::Distribution.new(|%(%meta.grep(?*.value.elems))) but Zef::Distribution::Local($path);
    }

    method find-meta(Zef::Distribution::Local: $path? is copy) {
        temp $path = do given $path {
            when IO::Path           { $path       }
            when Str && $path.chars { $path.IO    }
            default { self.IO // return IO::Path  }
        }
        return $path if $path.IO.f;

        # META.info and META6.info are not spec, but are still in use
        my $meta-basename = <META6.json META.info META6.info>.first(-> $basename {
            # the windows path size check is for windows compatability when
            # for when module authors symlink META.info to META6.json
            # "12" is the minimum size required for a valid meta that
            # rakudos internal json parser can understand (and is longer than
            # what the symlink issue noted above usually involves)
            temp $path = $path.child($basename);
            so ($path.e && ($*DISTRO.is-win ?? ((try $path.s) > 12) !! $path.f));
        }) // return IO::Path;

        $ = $path.child($meta-basename);
    }

    method resources {
        my $res-path := $!IO.child('resources');
        my $lib-path := $res-path.child('libraries');

        % = self.hash<resources>.map: -> $resource {
            $resource => $resource ~~ m/^libraries\/(.*)/
                ?? $lib-path.child($*VM.platform-library-name(IO::Path.new($0, :CWD($!path))))
                !! $res-path.child($resource);
        }
    }

    method sources(Bool :$absolute) {
        % = self.hash<provides>.grep(*.so).map({
            .key => .value.IO.is-relative
                ?? ( ?$absolute ?? .value.IO.absolute($!path) !! .value )
                !! ( !$absolute ?? .value.IO.relative($!path) !! .value );
        }).hash;
    }

    method scripts {
        % = do with $.IO.child('bin') -> $bin { $bin.dir.grep(*.IO.f).map({ .IO.basename => $_ }).hash if $bin.IO.d };
    }

    method IO { $!IO //= $!path.IO }
}
