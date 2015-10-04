unit module PathTools;

# :r - recursion
# :f - files
# :d - directories

sub ls(Str(Cool) $p, Mu :$test = none('.', '..'), *%opts) is export {
    return unless $p ~~ $test;
    return unless $p.IO.e;
    return $p if $p.IO.f && !(%opts<f>.DEFINITE && %opts<f>.not);
    return ($p.IO.dir, ($p.IO.dir>>.&ls(|%opts) if ?%opts<r>)).flat.grep({
            ($_.IO.f && !(%opts<f>.DEFINITE && %opts<f>.not)) 
        ||  ($_.IO.d && !(%opts<d>.DEFINITE && %opts<d>.not));
    }).grep(*.IO.e).map(*.IO.absolute).unique; 
    # unique is required to filter out file paths that get duplicated on recursion
    # and could theoretically be filtered out in a more "correct" but less concise way
}

sub rm(*@paths, *%opts) is export {
    my @ls = flat (@paths>>.&ls(|%opts)>>.Slip)>>.Slip;
    my @delete-us  = sort { -.chars }, @ls>>.Str;
    my @deleted    = ~$_ for @delete-us.grep(*.IO.e).grep: {try { $_.IO.d ?? $_.IO.rmdir !! $_.IO.unlink}}
}

sub mkdirs($p, *%opts) is export {
    my $path-copy = $p;
    my @mkdirs = eager gather { loop {
        last if ($path-copy.IO.e && $path-copy.IO.d);
        take $path-copy;
        last unless $path-copy := $path-copy.IO.dirname;
    } }
    return @mkdirs ?? @mkdirs.reverse.map({ ~mkdir($_) }).[*-1] !! ();
}

sub mktemp($p = &tmpdir(), *%opts) is export {
    die "Cannot call mktemp on a directory that already exists" if $p.IO.e && $p.IO.d;
    state @delete-us;
    with mkdirs($p, |%opts) -> $path { @delete-us.append(~$path); return ~$path }
    END { rm(|@delete-us, :r, :f, :d) }
}

# will make this an export once it is more robust for handling failures
# such as theoretically exhausting the for loop limit
my sub tmpdir {
    state $lock = Lock.new;
    state $id   = 0;
    state @cache; # So we don't return the same path in 2 different calls when user has not created the tmpdir yet
    $lock.protect({ 
        for ^100 { # retry a max number of times
            my $gen-path = $*TMPDIR.child("p6mktemp").child("{time}_{++$id}").IO;
            if ((!$gen-path.e || $gen-path.e && !$gen-path.d) && $gen-path !~~ @cache) {
                @cache.append(~$gen-path);
                return ~$gen-path;
            }
        }
    });
}