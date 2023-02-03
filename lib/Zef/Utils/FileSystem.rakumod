module Zef::Utils::FileSystem {

    =begin pod

    =title module Zef::Utils::FileSystem

    =subtitle Utility subroutines for interacting with the file system

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef::Utils::FileSystem;

        # Recursively list, copy, move, or delete paths
        my @files_in_lib      = list-paths("lib/");
        my @copied_to_lib2    = copy-paths("lib/", "lib2/");
        my @moved_to_lib3     = move-paths("lib2/", "lib3/");
        my @deleted_from_lib3 = delete-paths("lib3/");

        # Locate a bin script from $PATH
        my $zef_in_path = Zef::Utils::FileSystem::which("zef");
        say "zef bin location: {$zef_in_path // 'n/a'}";

        # A Lock.protect like interface that is backed by a file lock
        my $lock-file = $*TMP.add("myapp.lock");
        lock-file-protect($lock-file, {
            # do some work here that may want to use cross-process locking
        });

    =end code

    =head1 Description

    Provides additional facilities for interacting with the file system.

    =head1 Subroutines

    =head2 sub list-paths

        sub list-paths(IO() $path, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot --> Array[IO::Path])

    Returns an C<Array> of C<IO::Path> of all paths under C<$path>.

    If C<:$d> is C<True> directories will be returned.

    If C<$f> is set to C<False> then files will not be returned.

    If C<$r> is set to C<False> it will not recurse into directories.

    If C<$dot> is C<True> then the current directory may be included in the return results.

    =head2 sub copy-paths

        sub copy-paths(IO() $from-path, IO() $to-path, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot --> Array[IO::Path])

    Copy all paths under C<$from-path> to a directory C<$to-path> and returns an C<Array> of C<IO::Path> of the successfully
    copied files (their new locations).

    If C<:$d> is C<True> directories without files may be created.

    If C<$f> is set to C<False> then files will not be copied.

    If C<$r> is C<False> it will not recurse into directories.

    If C<$dot> is C<True> then the current directory may be copied.

    =head2 sub move-paths
    
        sub move-paths(IO() $from-path!, IO() $to-path, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot --> Array[IO::Path])

    Move all paths under C<$from-path> to a directory C<$to-path> and returns an C<Array> of C<IO::Path> of the successfully
    moved files (their new locations).

    If C<:$d> is C<False> directories without files won't be created.

    If C<$f> is set to C<False> then files will not be moved.

    If C<$r> is C<False> it will not recurse into directories. If C<$dot> is C<True> then the current directory may be moved.

    =head2 sub delete-paths
    
        sub delete-paths(IO() $path!, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot --> Array[IO::Path])

    Delete all paths under C<$path> and returns an C<Array> of C<IO::Path> of what was deleted.

    If C<:$d> is C<False> directories without files won't be deleted.

    If C<$f> is set to C<False> then files will not be deleted.

    If C<$r> is C<False> it will not recurse into directories.

    If C<$dot> is C<True> then the current directory may be deleted.

    =head2 sub file-lock-protect
    
        sub lock-file-protect(IO() $path, &code, Bool :$shared = False)

    Provides an interface similar to C<Lock.protect> that is backed by a file lock on C<$path> instead of a semaphore.
    Its purpose is to help keep multiple instances of zef from trying to edit the e.g. p6c/cpan ecosystem index at the
    same time (although how well it serves that purpose in practice is unknown).

    =head2 sub which

        our sub which(Str $name --> Array[IO::Path])

    Search the current env C<PATH>, returning an C<Array> of C<IO::Path> with paths that contain a matching file C<$name>.
    This is used for determining if a dependency such as C<curl:from<bin>> is installed.

    =end pod

    sub list-paths(IO() $path, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot --> Array[IO::Path]) is export {
        die "{$path} does not exists" unless $path.e;
        my &wanted-paths := -> @_ { grep { .basename.starts-with('.') && !$dot ?? 0 !! 1 }, @_ }

        my IO::Path @results = gather {
            my @stack = $path.f ?? $path !! dir($path);
            while @stack.splice -> @paths {
                for wanted-paths(@paths) -> IO() $current {
                    take $current if ($current.f && ?$f) || ($current.d && ?$d);
                    @stack.append(dir($current)) if ?$r && $current.d;
                }
            }
        }
        return @results;
    }

    sub copy-paths(IO() $from-path, IO() $to-path, Bool :$d, Bool :$f = True, Bool :$r = True, Bool :$dot --> Array[IO::Path]) is export {
        die "{$from-path} does not exists" unless $from-path.IO.e;
        mkdir($to-path) if $from-path.d && !$to-path.e;

        my IO::Path @results = eager gather for list-paths($from-path, :$d, :$f, :$r, :$dot).sort -> $from-file {
            my $from-relpath = $from-file.relative($from-path);
            my $to-file      = IO::Path.new($from-relpath, :CWD($to-path)).resolve;
            mkdir($to-file.parent) unless $to-file.e;
            take $to-file if copy($from-file, $to-file);
        }
        return @results;
    }

    sub move-paths(IO() $from-path, IO() $to-path, Bool :$d = True, Bool :$f = True, Bool :$r = True, Bool :$dot --> Array[IO::Path]) is export {
        my IO::Path @copied  = copy-paths($from-path, $to-path, :$d, :$f, :$r, :$dot);
        @ = delete-paths($from-path, :$d, :$f, :$r, :$dot);
        return @copied;
    }

    sub delete-paths(IO() $path, Bool :$d = True, Bool :$f = True, Bool :$r = True, Bool :$dot = True --> Array[IO::Path]) is export {
        my @paths = list-paths($path, :$d, :$f, :$r, :$dot).unique(:as(*.absolute));
        my @files = @paths.grep(*.f);
        my @dirs  = @paths.grep(*.d);
        $path.f ?? @files.push($path.IO) !! @dirs.push($path.IO);

        my IO::Path @results = eager gather {
            for @files.sort(*.chars).reverse { take $_ if try unlink($_) }
            for @dirs.sort(*.chars).reverse { take $_ if try rmdir($_) }
        }
        return @results;
    }

    sub lock-file-protect(IO() $path, &code, Bool :$shared = False) is export {
        do given ($shared ?? $path.IO.open(:r) !! $path.IO.open(:w)) {
            LEAVE {.close}
            LEAVE {try .path.unlink}
            .lock(:$shared);
            code();
        }
    }

    our sub which(Str $name --> Array[IO::Path]) {
        my $source-paths  := $*SPEC.path.grep(*.?chars).map(*.IO).grep(*.d);
        my $path-guesses  := $source-paths.map({ $_.child($name) });
        my $possibilities := $path-guesses.map(-> $path {
            ((BEGIN $*DISTRO.is-win)
                ?? ($path.absolute, %*ENV<PATHEXT>.split(';').map({ $path.absolute ~ $_ }))
                !! $path.absolute)
        });

        my IO::Path @results = $possibilities.flat.grep(*.defined).grep(*.IO.f).map(*.IO);
        return @results;
    }
}
