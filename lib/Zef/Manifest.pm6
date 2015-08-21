class Zef::Manifest {
    has $.basename;
    has $.cur;
    has $.create;
    has %.hash;
    has $!lock;

    submethod BUILD(:$!cur, :$!basename = 'MANIFEST', Bool :$!create) {
        $!lock := Lock.new;
        $!cur   = CompUnitRepo::Local::Installation.new($!cur)\
            unless $!cur.isa(CompUnitRepo::Local::Installation);

        with $!cur.IO.child($!basename) -> $mani-path {
            if !$mani-path.IO.e || !$mani-path.IO.f {
                die "No MANIFEST available for: {~$mani-path}, pass `:create` if you'd like it generated as needed."\
                    unless $!create;
                %!hash  = self.GEN-MANIFEST();
            }
            else {
                %!hash  = from-json( $mani-path.IO.slurp ).hash;
            }
        }
    }

    # this can be put somewhere more appropriate later
    method uninstall($dist) {
        $!lock.protect( {
        my $repo         = %!hash;
        my @candi        = $!cur.candidates($dist.name, :auth($dist.auth), :ver($dist.ver)) or return False;
        my $delete-idx   = $repo<dists>.first-index({ $_<id> eq @candi[0]<id> });

        my @provides  = $repo<dists>[$delete-idx]<provides>.values>>.values.flat.map({ $_.<file> }).list;
        my @bins      = $repo<dists>[$delete-idx]<files>.flat>>.values.flat;
        my @wrappers  = $repo<dists>[$delete-idx]<files>.flat>>.keys.flat.map({"{$_}", "{$_}-m", "{$_}-j"}).flat;
        # .candidates doesn't let us search for @wrappers, so in the future we need to *not* delete wrappers
        # if there is another version of the same module installed.
        my @all-files = (@provides, @bins, @wrappers).flat;

        for @all-files -> $file is copy {
            try {
                $file = $file.Str.IO.is-absolute ?? $file.Str.IO !! $file.Str.IO.absolute($!cur);
                unlink($file);
            }
        }

        with $delete-idx -> $index { $repo<dists>.splice($index, 1) }
        my $dists = $repo.hash.<dists>;
        $.WRITE-MANIFEST($dists);
        } );
    }

    method write { self.WRITE-MANIFEST(%!hash<dists>.flat) }

    method path  { $!cur.IO.child($!basename) }



    method dist-count { %!hash<dists>.flat.elems }

    method file-count { $.files(:bin, :provides).flat.elems }

    method files(Bool :$bin = True, Bool :$provides) {
        my @files;
        for %!hash<dists>.flat -> $dist {
            if ?$bin {
                @files.push($_) for $dist<files>.values.flat.list;
            }
            if ?$provides {
                @files.push($_) for $dist<provides>.values>>.values.flat.map({ $_.<file> }).list;
            }
            #if ?$wrappers {
            #
            #}
        }
        @files.grep(*.so).list;
    }

    method GEN-MANIFEST(*@dists) {
        my $repo;
        $repo<dists>      := @dists.flat.list;
        $repo<dist-count> := @dists.flat.elems;
        $repo<file-count> := $.file-count(:bin, :provides);
        $repo;
    }

    method WRITE-MANIFEST(*@dists) {
        $!lock.protect({
        my $repo = self.GEN-MANIFEST(@dists.flat);
        %!hash   = $repo.hash;
        $.path.IO.spurt: to-json( $repo )
        });
    }
}
