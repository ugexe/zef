unit module PathTools;

sub ls(Str(Cool) $path, Bool :$f = True, Bool :$d = True, Bool :$r, *%_) is export {
    return () unless $path.IO.e;
    return $path if ($path.IO.f && ?$f) && (!%_<test> || $path ~~ %_<test>);
    return ( try $path.IO.dir(|%_).grep({ ($_.IO.f && ?$f) || ($_.IO.d && ?$d) }), 
             try ($path.IO.dir(|%_)>>.&ls(:$f, :$d, |%_) if ?$r) )\
            .flat.grep(*.IO.e).map(*.IO.absolute).unique; 
    # unique is required to filter out file paths that get duplicated on recursion
    # and could theoretically be filtered out in a more "correct" but less concise way
}

sub rm(*@paths, Bool :$f = True, Bool :$d = True, Bool :$r, *%_) is export {
    my @ls = flat (@paths>>.&ls(:$f, :$d, :$r, |%_)>>.Slip)>>.Slip;
    my @delete-us  = sort { -.chars }, @ls>>.Str;
    my @deleted    = ~$_ for @delete-us.grep(*.IO.e).grep: {try { $_.IO.d ?? $_.IO.rmdir !! $_.IO.unlink}}
}

sub mkdirs($path, *%_) is export {
    my $path-copy = $path;
    my @mkdirs = eager gather { loop {
        last if ($path-copy.IO.e && $path-copy.IO.d);
        take $path-copy;
        last unless $path-copy := $path-copy.IO.dirname;
    } }
    return @mkdirs ?? @mkdirs.reverse.map({ ~mkdir($_, |%_) }).[*-1] !! ();
}

sub mktemp($path = &tmpdir(), *%_) is export {
    die "Cannot call mktemp on a directory that already exists" if $path.IO.e && $path.IO.d;
    state @delete-us;
    with mkdirs($path, |%_) -> $p { @delete-us.append(~$p); return ~$p }
    END { rm(|@delete-us, :r, :f, :d) }
}

sub tmpdir(Str(Cool) $base where *.chars = $*TMPDIR) is export {
    state $lock = Lock.new;
    state $id   = 0;
    state @cache; # So we don't return the same path in 2 different calls when user has not created the tmpdir yet
    $lock.protect({
        for ^100 { # retry a max number of times
            my $gen-path = $base.IO.child("p6mktemp").child("{time}_{++$id}").IO;
            if ((!$gen-path.e || $gen-path.e && !$gen-path.d) && $gen-path !~~ @cache) {
                @cache.append(~$gen-path);
                return ~$gen-path;
            }
        }
    });
}
