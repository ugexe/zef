class Zef::Utils::FileSystem;
# todo: inherit from IO::Path

has $.path;
has $!tmp;

submethod BUILD(:$!path, :$!tmp = False) { }

method ls($path = $.path, Bool :$f, Bool :$d, Bool :$r) {
    ls($path, $f, $d, $r);
}

method rm($path = $.path, Bool :$f, Bool :$d, Bool :$r) {
    rm($path, $f, $d, $r);
}

method mkdirs($path = $.path, :$mode) {
    mkdirs($path, :$mode);
}

method extract-deps($path = $.path) {
    extract-deps($path);
}


sub ls($path, Bool :$f = True, Bool :$d = True, Bool :$r) is export(:DEFAULT) { 
    return () unless $path.defined && $path.IO.e;
    my @results := eager gather {
        my @paths = $path;
        while @paths.pop -> $p {
            take $p if (($d && $p.IO.d) || ($f && $p.IO.f));

            if ((once { 1 } || $r) && $p.IO.d) {
                for dir($p) -> $sp {
                    @paths.push($sp);
                }
            }
        }
    }

    return @results;
}

sub rm($path, Bool :$f, Bool :$d, Bool :$r) is export(:DEFAULT) {
    return () unless $path.defined && $path.IO.e;
    my @files = ls($path, :$f, :$r);
    my @dirs  = ls($path, :$d, :$r);

    my @deleted; 
    for @files -> $file { @deleted.push($file) if $file.IO.unlink }
    for @dirs.sort({ -.chars }) -> $delete-dir { @deleted.push($delete-dir) if rmdir($delete-dir) }

    return @deleted;
}

sub mkdirs($path, :$mode) is export(:DEFAULT) { 
    my $path-copy = $path;
    my @mkdirs := gather { # not the pretty way, but works on jvm
        loop {
            last if ($path-copy.IO.e && $path-copy.IO.d);
            take $path-copy;
            last unless $path-copy := $path-copy.IO.dirname;
        }
    }

    # recusively make directories, but only return last successful created directory
    try ~@mkdirs.reverse.map({ try {mkdir($_)} }).[*-1];
}

sub extract-deps($path) is export(:DEFAULT) {
    die "$path does not exist" unless $path.IO ~~ :d;
    my @minimeta;
    my @modules = ls($path, :f, :r).grep(*.IO.f).grep({ $_.IO.basename ~~ / \.pm6? $/ });
    my $slash = / [ \/ | '\\' ]  /;
    for @modules -> $f is copy {
        my @depends;
        if my $t = $f.slurp {
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
            name => $f.path.subst(/^"{$path.Str}"<$slash>/,'').subst(/^'lib'<$slash>/, '').subst(/^'lib6'<$slash>/, '').subst(/\.pm6?$/, '').subst($slash, '::', :g),
            file => $f.path,
            dependencies => @depends, 
        });
    }

    return @(@minimeta);
}
