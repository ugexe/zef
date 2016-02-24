unit module Zef::Utils::FileSystem;

sub list-paths($path, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot) is export {
    die "{$path} is not a valid path" unless ?$path && $path.?chars && $path.IO.e;
    my @stack = $path.IO.absolute;
    my $paths := gather while ( @stack ) {
        my $current = @stack.pop;
        next if $current.IO.basename.starts-with('.') && !$dot;
        take $current.IO if ($current.IO.f && ?$f) || ($current.IO.d && ?$d);
        @stack.append(dir($current)>>.path) if ?$r && $current.IO.d;
    }
}

sub copy-paths($from-path, $to-path, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot) is export {
    die "{$from-path} is not a valid path" unless ?$from-path && $from-path.?chars && $from-path.IO.e;
    mkdir($to-path) unless $to-path.IO.e;
    my @files  = list-paths($from-path, :$d, :$f, :$r, :$dot).sort;
    my @copied = gather for @files -> $from-file {
        my $from-relpath = $from-file.relative($from-path);
        my $to-file      = IO::Path.new($from-relpath, :CWD($to-path)).absolute;
        mkdir($to-file.IO.parent) unless $to-file.IO.e;
        take $to-file.IO.absolute if copy($from-file, $to-file);
    }
}

sub move-paths($from-path, $to-path, Bool :$d = True, Bool :$f = True, Bool :$r = True, Bool :$dot) is export {
    my @copied  = copy-paths($from-path, $to-path, :$d, :$f, :$r, :$dot);
    my @deleted = delete-paths($from-path, :$d, :$f, :$r, :$dot);
    @copied;
}

sub delete-paths($path, Bool :$d = True, Bool :$f = True, Bool :$r = True, Bool :$dot = True) is export {
    my @paths   = list-paths($path, :$d, :$f, :$r, :$dot).unique(:as(*.absolute));
    my @files   = @paths.grep(*.f);
    my @dirs    = @paths.grep(*.d);
    $path.IO.f ?? @files.push($path.IO) !! @dirs.push($path.IO);
    my @deleted = do gather {
        for @files.sort(*.chars).reverse { unlink($_) && take $_ }
        for @dirs\.sort(*.chars).reverse { rmdir($_)  && take $_ }
    }
}
