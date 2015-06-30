use MONKEY-TYPING;

# Add some recursive helpers to IO::Path with new names to help avoid accidents from the MONKEY
augment class IO::Path {
    # :r Recursive
    # :d Include directories
    # :f Include files
    # :a Include .files and .folders
    method ls(IO::Path:D: Bool :$f = True, Bool :$d = True, Bool :$r, Bool :$a = False, |c) {
        my @results = eager gather {
            my @paths = $.path.IO.d ?? $.path.IO.dir(|c) !! $.path;
            while @paths.pop -> $p {
                next if !$a && $p.IO.basename.starts-with('.');
                given $p.IO {
                    when :d {
                        take $p if $d;

                        if $r {
                            for $_.IO.dir(|c) -> IO::Path $sp {
                                @paths.push: $sp;
                            }
                        }
                    }
                    when :f {
                        take $p if $f;
                    }
                }
            }
        }

        return @results;
    }

    method rm(IO::Path:D: Bool :$f = True, Bool :$d = False, Bool :$r = False, |c) {
        my @paths = self.ls(:$f, :$d, :$r, |c);
        my @files = @paths.grep(*.IO.f); # >>.resolve; On windows this returns C:\C:\path
        my @dirs  = @paths.grep(*.IO.d);

        my @deleted; 
        for @files -> $file { @deleted.push($file) if $file.IO.unlink }
        for @dirs.sort({ -.chars }) -> $delete-dir { @deleted.push($delete-dir) if rmdir($delete-dir) }
        @deleted.push($.path.IO) if ($.path.IO.d ?? $.path.IO.rmdir !! $.path.IO.unlink);
        
        return @deleted;
    }

    method mkdirs(IO::Path:D: :$mode = 0o777) { 
        my $path-copy = $.path;
        my @mkdirs = eager gather { # not the pretty way, but works on jvm
            loop {
                last if ($path-copy.IO.e && $path-copy.IO.d);
                take $path-copy;
                last unless $path-copy := $path-copy.IO.dirname;
            }
        }

        # recusively make directories, but only return last successful created directory
        return @mkdirs ?? try { ~@mkdirs.reverse.map({ mkdir($_, $mode) }).[*-1] } !! ();
    }
}

proto sub ls(|) is export { * }
multi sub ls(*%_) { 
    my $p = $*SPEC.curdir.IO;
    $p.ls(:!absolute, |%_);
}
multi sub ls(IO::Path:D $path, |c) {
    $path.ls(|c)
}
multi sub ls(Cool $path, |c) {
    $path.IO.ls(|c)
}


proto sub rm(|) is export { * }
multi sub rm(*%_) { 
    my $p = $*SPEC.curdir.IO does Zef::Utils::PathTools;
    $p.rm(:!absolute, |%_);
}
multi sub rm(IO::Path:D $path, |c) {
    $path.rm(|c)
}
multi sub rm(Cool $path, |c) {
    $path.IO.rm(|c);
}


proto sub mkdirs(|) is export { * }
multi sub mkdirs(*%_) { 
    my $p = $*SPEC.curdir.IO does Zef::Utils::PathTools;
    $p.mkdirs(|%_);
}
multi sub mkdirs(IO::Path:D $path, |c) {
    $path.mkdirs;
}
multi sub mkdirs(Cool $path) {
    $path.IO.mkdirs;
}