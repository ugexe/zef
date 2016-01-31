unit module Zef::Utils::FileSystem;

sub ls-files ($path) is export {
    my @stack = $path.IO.absolute;
    my $test-files := gather while ( @stack ) {
        my $current = @stack.pop;
        take $current.IO if $current.IO.f;
        @stack.append(dir($current)>>.path) if $current.IO.d;
    }
}

sub copy-files($from-dir, $to-dir) is export {
    mkdir($to-dir) unless $to-dir.IO.e;

    my @files = ls-files($from-dir).sort;

    for @files -> $from-file {
        my $from-relpath = $from-file.relative($from-dir);
        my $to-file      = IO::Path.new($from-relpath, :CWD($to-dir)).absolute;
        mkdir($to-file.IO.dirname) unless $to-file.IO.e;
        copy($from-file, $to-file);
    }
}
