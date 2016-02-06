unit module Zef::Utils::FileSystem;

sub ls-files ($path) is export {
    my @stack = $path.IO.absolute;
    my $test-files := gather while ( @stack ) {
        my $current = @stack.pop;
        take $current.IO if $current.IO.f;
        @stack.append(dir($current)>>.path)\
            if $current.IO.d && !$current.IO.basename.starts-with('.');
    }
}

sub copy-files($from-dir, $to-dir) is export {
    mkdir($to-dir) unless $to-dir.IO.e;
    my @files  = ls-files($from-dir).sort;
    my @copied = gather for @files -> $from-file {
        my $from-relpath = $from-file.relative($from-dir);
        my $to-file      = IO::Path.new($from-relpath, :CWD($to-dir)).absolute;
        mkdir($to-file.IO.dirname) unless $to-file.IO.e;
        take $to-file.IO.absolute if copy($from-file, $to-file);
    }
}

sub move-files($from-dir, $to-dir) is export {
    my @files = copy-files($from-dir, $to-dir);
    my @dirs  = @files.map(*.IO.dirname).unique;
    for @files.sort(*.chars).reverse -> $path { unlink($_) }
    for @dirs\.sort(*.chars).reverse -> $path { rmdir($_)  }
    @files;
}