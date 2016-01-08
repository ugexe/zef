use Zef::Distribution;

role Zef::Distribution::Local {
    has $.path;

    method new(Str(Cool) $path where *.?chars) {
        my $meta-path = $path.IO.child(<META.info META6.json>\
            .first(*.IO.absolute($path).IO.e)) or die "No meta file?";
        my %meta = from-json($meta-path.IO.slurp);
        $ = Zef::Distribution.new(|%(%meta.grep(?*.value.elems))) but Zef::Distribution::Local($path);
    }

    method resources {
        % = self.hash<resources>.map: { $_ => $!path.IO.child('resources').child($_) }
    }

    method sources(Bool :$absolute) {
        % = self.hash<provides>.grep(*.so).map({
            .key => .value.IO.is-relative
                ?? ( ?$absolute ?? .value.IO.absolute($!path) !! .value )
                !! ( !$absolute ?? .value.IO.relative($!path) !! .value );
        }).hash;
    }

    method scripts {
        % = do with self.IO.child('bin') -> $bin { $bin.dir.grep(*.IO.f).map({ .IO.basename => $_ }).hash if $bin.IO.d };
    }

    method IO { "{self.path.IO.absolute}".IO }
}
