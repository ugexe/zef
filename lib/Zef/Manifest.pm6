class Zef::Manifest {
    has $.basename; # use different name? $curli.Str ~ / $.basename = full path of MANIFEST
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
                %!hash  = self.read();
            }
            else {
                %!hash  = from-json( $mani-path.IO.slurp ).hash;
            }
        }
    }


    method write(*@dists, Int :$dist-count, Int :$file-count) {
        $!lock.protect({
        try { mkdir(~$!cur) unless $!cur.IO.e }

        my $repo = self.read(|@dists);

        with $dist-count -> $count { $repo<dist-count> = $dist-count }
        with $file-count -> $count { $repo<file-count> = $file-count }

        $.path.IO.spurt: to-json( $repo )
        });
    }

    method read(*@dists) {
        my @source = @dists.elems ?? @dists !! %!hash<dists>.flat;
        my $repo;
        $repo<dists>       = @source;
        $repo<dist-count>  = @source.elems;
        # todo: call .file-count on @source
        $repo<file-count>  = $.file-count(:bin, :provides);
        $repo;
    }

    method path       { $!cur.IO.child($!basename).IO       }
    method dist-count { %!hash<dists>.flat.elems            }
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
        my @dists = $repo<dists>.flat;
        self.write(@dists);
        } );
    }
}
