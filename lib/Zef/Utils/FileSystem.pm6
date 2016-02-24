unit module Zef::Utils::FileSystem;

sub list-paths($path, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot) is export {
    my @stack = $path.IO.absolute;
    my $paths := gather while ( @stack ) {
        my $current = @stack.pop;
        next if $current.IO.basename.starts-with('.') && !$dot;
        take $current.IO if ($current.IO.f && ?$f) || ($current.IO.d && ?$d);
        @stack.append(dir($current)>>.path) if ?$r && $current.IO.d;
    }
}

sub copy-paths($from-path, $to-path) is export {
    mkdir($to-path) unless $to-path.IO.e;
    my @files  = list-paths($from-path).sort;
    my @copied = gather for @files -> $from-file {
        my $from-relpath = $from-file.relative($from-path);
        my $to-file      = IO::Path.new($from-relpath, :CWD($to-path)).absolute;
        mkdir($to-file.IO.dirname) unless $to-file.IO.e;
        take $to-file.IO.absolute if copy($from-file, $to-file);
    }
}

sub move-paths($from-path, $to-path) is export {
    my @files = copy-paths($from-path, $to-path);
    my @dirs  = @files.map(*.parent).unique(:as(*.absolute));
    for @files.sort(*.chars).reverse { unlink($_) }
    for @dirs\.sort(*.chars).reverse { rmdir($_)  }
    @files;
}

sub delete-paths($dir) is export {
    my @paths = list-paths($dir, :d, :dot).unique(:as(*.absolute));
    my @files = @paths.grep(*.f);
    my @dirs  = @paths.grep(*.d);
    for @files.sort(*.chars).reverse { unlink($_) }
    for @dirs\.sort(*.chars).reverse { rmdir($_)  }
    True
}
