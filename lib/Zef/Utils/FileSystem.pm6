unit module Zef::Utils::FileSystem;

sub list-paths(IO() $path!, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot) is export {
    die "{$path} does not exists" unless $path.e;
    my &wanted-paths := -> @_ { grep { .basename.starts-with('.') && !$dot ?? 0 !! 1 }, @_ }

    gather {
        my @stack = $path.f ?? $path !! dir($path);
        while @stack.splice -> @paths {
            for wanted-paths(@paths) -> IO() $current {
                take $current if ($current.f && ?$f) || ($current.d && ?$d);
                @stack.append(dir($current)) if ?$r && $current.d;
            }
        }
    }
}

sub copy-paths(IO() $from-path!, IO() $to-path, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot) is export {
    die "{$from-path} does not exists" unless $from-path.IO.e;
    mkdir($to-path) unless $to-path.e;

    eager gather for list-paths($from-path, :$d, :$f, :$r, :$dot).sort -> $from-file {
        my $from-relpath = $from-file.relative($from-path);
        my $to-file      = IO::Path.new($from-relpath, :CWD($to-path));
        mkdir($to-file.parent) unless $to-file.e;
        next if $from-file eq $to-file; # copy deadlocks on older rakudos otherwise
        take $to-file if copy($from-file, $to-file);
    }
}

sub move-paths(IO() $from-path, IO() $to-path, Bool :$d = True, Bool :$f = True, Bool :$r = True, Bool :$dot) is export {
    my @copied  = copy-paths($from-path, $to-path, :$d, :$f, :$r, :$dot);
    my @deleted = delete-paths($from-path, :$d, :$f, :$r, :$dot);
    @copied;
}

sub delete-paths(IO() $path, Bool :$d = True, Bool :$f = True, Bool :$r = True, Bool :$dot = True) is export {
    my @paths = list-paths($path, :$d, :$f, :$r, :$dot).unique(:as(*.absolute));
    my @files = @paths.grep(*.f);
    my @dirs  = @paths.grep(*.d);
    $path.f ?? @files.push($path.IO) !! @dirs.push($path.IO);

    eager gather {
        for @files.sort(*.chars).reverse { take $_ if try unlink($_) }
        for @dirs\.sort(*.chars).reverse { take $_ if try rmdir($_) }
    }
}

sub lock-file-protect($path, &code, Bool :$shared = False) is export {
    do given ($shared ?? $path.IO.open(:r) !! $path.IO.open(:w)) {
        LEAVE {.close}
        LEAVE {try .path.unlink}
        .lock(:$shared);
        code();
    }
}

our sub which($name) {
    my $source-paths  := $*SPEC.path.grep(*.?chars).map(*.IO).grep(*.d);
    my $path-guesses  := $source-paths.map({ $_.child($name) });
    my $possibilities := $path-guesses.map: -> $path {
        ((BEGIN $*DISTRO.is-win)
            ?? ($path.absolute, %*ENV<PATHEXT>.split(';').map({ $path.absolute ~ $_ }).Slip)
            !! $path.absolute).Slip
    }

    return $possibilities.grep(*.defined).grep(*.IO.f);
}
