class Zef::Utils::FileSystem;
# todo: inherit from IO::Path

has $.path;
has $!tmp;

submethod BUILD(:$!path, :$!tmp = False) { }

method ls($path = $.path, Bool :$f, Bool :$d, Bool :$r) {
    return () unless $path.defined && $path.IO.e;
    my @results;
    my $paths = Supply.new;

    $paths.grep(*.d).tap(-> $dir-path {
        @results.push($dir-path);
    }) if $d;

    $paths.grep(*.f).tap(-> $file-path { 
        @results.push($file-path);
    }) if $f;

    $paths.grep(*.d).tap(-> $dir-path {
        $paths.emit($_) for dir($dir-path);
    }) if $r;

    if !$r && $path.IO.d { @results.push($_) for dir($path.IO) }
    $paths.emit($path.IO);


    return @results;
}


method rm($path = $.path, Bool :$f, Bool :$d, Bool :$r) {
    return () unless $path.defined && $path.IO.e;
    my @files = self.ls($path, :$f, :$r, d => False);
    my @dirs  = self.ls($path, :$d, :$r, f => False);

    my @deleted; 
    for @files -> $file { @deleted.push($file) if $file.unlink }
    for @dirs.sort({ -.chars }) -> $delete-dir { @deleted.push($delete-dir) if rmdir($delete-dir) }

    return @deleted;
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
