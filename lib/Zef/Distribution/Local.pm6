use Zef::Distribution;

role Zef::Distribution::Local {
    has $.path;
    has $!IO;

    method new(Str(Cool) $path where *.?chars) {
        my $meta-path = $path.IO.child(<META.info META6.json>\
            .first(*.IO.absolute($path).IO.e)) or die "No meta file?";
        my %meta = from-json($meta-path.IO.slurp);
        $ = Zef::Distribution.new(|%(%meta.grep(?*.value.elems))) but Zef::Distribution::Local($path);
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
