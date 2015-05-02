class Zef::Utils::Depends;

method build-dep-tree(@metas is copy) {
    my @tree;

    sub visit(%meta is rw) {
        unless %meta<marked>++ {
            for %meta<dependencies>.list -> $dep-name {
                for @metas.grep({ $_.<name> eq $dep-name }) -> %sub-meta is rw {
                    visit(%sub-meta);
                }
            }
            @tree.push({ %meta });
        }
    }

    for @metas -> %meta {
        visit(%meta);
    }

    return @tree;
}

method compress(@tree is copy) {
    my @ctree;
    my ($i, $level) = 0, 0;
    for @tree -> $n {
        for $i == 0 ?? () !! @tree[0..$i-1] -> $l {
            $level++ if $n<dependencies>.grep($l<name>);
        }
        while $level > @ctree.elems {
            @ctree.push([]);
        }
        @ctree[$level].push($n);
        $i++;
        $level = 0;
    }

    return @ctree.grep({ $_.elems > 0 });
}


sub extract-deps(*@paths) is export {
    my @minimeta;
    my @modules = @paths.grep(*.IO.f).grep({ $_.IO.basename ~~ / \.pm6? $/ });
    my $slash = / [ \/ | '\\' ]  /;
    for @modules -> $f is copy {
        my @depends;
        if my $t = $f.slurp {
            while $t ~~ /^^ \s* '=begin' \s+ <ident> .* '=end' \s+ <ident> / {
                $t = $t.substr(0,$/.from) ~ $t.substr($/.to);
            }
            for $t.lines -> $l {
                if $l ~~ /^ \s* ['use'||'need'||'require'] \s+ (\w+ ['::' \w+]*)/ {
                    @depends.push($0.Str) if $0 !~~ any('MONKEY', 'v6');
                }
            }
        }
        @minimeta.push({
            name => $f.path.subst(/^.*?<$slash>?lib<$slash>/,'').subst(/\.pm6?$/, '').subst($slash, '::', :g),
            file => $f.path,
            dependencies => @depends, 
        });
    }

    return @minimeta;
}