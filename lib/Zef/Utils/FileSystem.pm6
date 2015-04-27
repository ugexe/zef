class Zef::Utils::FileSystem;
# todo: inherit from IO::Path
has $.path;

method ls($path = $.path, Bool :$f, Bool :$d, Bool :$r, Mu :$test = $*SPEC.curupdir) {
    return () unless $path.IO.e;
    my @results;
    my $paths = Supply.from-list($path.IO.d ?? dir($path, :$test) !! $path.IO);

    $paths.grep(*.d).tap(-> $dir-path { 
        @results.push($dir-path);
    }) if $d;

    $paths.grep(*.f).tap(-> $file-path { 
        @results.push($file-path);
    }) if $f;

    $paths.grep(*.d).tap(-> $dir-path {
        $paths.emit($_) for dir($dir-path);
    }) if $r;

    $paths.wait;
    return @results;
}

method rm($path = $.path, Bool :$f, Bool :$d, Bool :$r, Mu :$test = $*SPEC.curupdir ) {
    my @files = self.ls($path, :$f, :$r, :$test);
    try @files>>.unlink;

    my @dirs = self.ls($path, :$d, :$r, :$test);
    # when .resolve is fixed to return IO::Path we should sort based on that
    for @dirs.sort({ -.chars }) -> $delete-dir {
        try { $delete-dir.rmdir };
    }

    try { $path.IO.rmdir } if ($path.IO.e && $path.IO.d);
}

method extract-deps($dir = $.path) {
    die "$dir does not exist" unless $dir.IO ~~ :d;
    my @minimeta;
    my @modules = self.ls($dir, :f, :r).grep(/\.pm6?/);
    my $slash = / [ '/' | '\\' ]  /;
    for @modules -> $f {
        my @depends;
        for $f.slurp -> $t is copy {
            while $t ~~ /^^ \s* '=begin' \s+ <ident> .* '=end' \s+ <ident> / {
                $t = $t.substr(0,$/.from) ~ $t.substr($/.to);
            }
            for $t.lines -> $l {
                if $l ~~ /^ \s* ['use'||'need'||'require'] \s+ (\w+ ['::' \w+]*)/ {
                    @depends.push($0.Str) if $0 !~~ any ('MONKEY_TYPING', 'v6');
                }
            }
        }
        @minimeta.push({
            name => $f.path.subst(/^"{$dir.Str}"<$slash>/,'').subst(/^'lib'<$slash>/, '').subst(/^'lib6'<$slash>/, '').subst(/\.pm6?$/, '').subst($slash, '::', :g),
            file => $f.path,
            dependencies => @depends, 
        });
    }

    return @(@minimeta);
}
