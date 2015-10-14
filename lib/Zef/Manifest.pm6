class Zef::Manifest {
    has $.basename; # use different name? $curli.Str ~ / $.basename = full path of MANIFEST
    has $.cur;
    has $.create;
    has %.hash;
    has $!lock;

    submethod BUILD(:$!cur, :$!basename = 'MANIFEST', Bool :$!create) {
        $!lock := Lock.new;
        $!cur   = CompUnitRepo::Local::Installation.new($!cur)\
            unless $!cur ~~ CompUnitRepo::Local::Installation;

        with $!cur.IO.child($!basename) -> $mani-path {
            if !$mani-path.IO.e || !$mani-path.IO.f {
                die "No MANIFEST available for: {~$mani-path}, pass `:create` if you'd like it generated as needed."\
                    unless $!create;
                %!hash = self.read();
            }
            else {
                %!hash = from-json( $mani-path.IO.slurp ).hash;
            }
        }
    }


    method write(@dists, Int :$dist-count, Int :$file-count) {
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
        $repo<dists>       = @source       // [ ];
        $repo<dist-count>  = @source.elems // 0;
        $repo<file-count>  = $.file-count  // 0;
        $repo;
    }

    method path       { $!cur.IO.child($!basename).IO       }
    method dist-count { %!hash<dists>.flat.elems            }
    method file-count {
        # CURLI appears to have named this confusingly as it is really a max value of all file ids
        # and not an actual count of anything.
        my $fc = [max] $.files(:bin, :provides).flat.cache;
        $fc > 0 ?? $fc !! 0; # max on empty array = -Inf
    }

    method files(Bool :$bin = True, Bool :$provides) {
        my @files;
        my @dists = %!hash<dists>.cache;
        @files <== map {.<files>.values} <== @dists if ?$bin;
        @files <== map {.<file>} <== map {.<provides>.values>>.values} <== @dists if ?$provides;

        @files.grep(*.so).cache;
    }

    # this can be put somewhere more appropriate later
    method uninstall($dist) {
        $!lock.protect( {
        my @deleted;
        my $repo  = %!hash;
        my $candi = $!cur.candidates($dist.name, :auth($dist.authority), :ver($dist.version)) or return False;
        my $delete-idx = $repo<dists>.first-index({ $_<id> eq DIST-PATH2ID($!cur, $candi.Str) });

        my @provides  <== map { .<file> } <== $repo<dists>[$delete-idx]<provides>.values>>.values;
        my @wrappers  <== map { "{$_}", "{$_}-m", "{$_}-j" } <== $repo<dists>[$delete-idx]<files>>>.keys;
        my @bins      <== $repo<dists>[$delete-idx]<files>>>.values;

        # .candidates doesn't let us search for @wrappers, so in the future we need to *not* delete wrappers
        # if there is another version of the same module installed.
        my  @to-delete  = flat (@provides, @bins, @wrappers);
        for @to-delete -> $file is copy {
            try {
                $file = $file.IO.is-absolute ?? ~$file !! ~$file.IO.absolute($!cur);
                unlink($file);
                @deleted.append($file);
            }
        }
        with $delete-idx -> $index { $repo<dists>[$index]:delete }
        my @dists = $repo<dists>.grep(*.so);
        self.write(@dists);
        @deleted;
        } );
    }
}

sub DIST-PATH2ID($cur, $path) {
    for $cur.dists.grep(*.so) -> $dist {
        for $dist<provides>.values -> $v {
            for $v.values -> $info {
                return $dist<id> if $info<file> eq $path.IO.basename;
            }
        }
    }
}
