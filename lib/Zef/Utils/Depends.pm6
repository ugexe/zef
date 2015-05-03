class Zef::Utils::Depends;

has @!metas;

submethod BUILD(:@!metas?) { }

grammar Grammar::Dependency::Parser {
    token TOP {
        [.*? <load-statement>]+ .*? $
    }

    token load-statement { <load-type> \s+ <short-name> }
    token short-name     { <name-piece> [<.colon-pair> <name-piece>]* }
    token name-piece     { <.name-token>+       }
    token name-token     { <+[\S] -restricted>  }
    token restricted     { <[:;{}\[\]\(\)./\\]>     }
    token colon-pair     { '::' }

    proto token load-type {*}
    token load-type:sym<use>     { <sym> }
    token load-type:sym<need>    { <sym> }
    token load-type:sym<require> { <sym> }
}

method build-dep-tree(@metas = @!metas) {
    my @tree;

    sub visit(%meta is rw) {
        unless %meta<marked>++ {
            &?ROUTINE($_.hash) for @metas.grep({ $_.<name> ~~ any(%meta<dependencies>.list) });
            @tree.push({ %meta });
        }
    }

    visit($_.hash) for @metas;

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

method extract-deps(*@paths) {
    @paths //= @!metas.grep({ $_.<file>.IO.basename ~~ /^ \.pm6? $/ });
    my @minimeta;
    my @modules = @paths.grep(*.IO.f).grep({ $_.IO.basename ~~ / \.pm6? $/ });
    my $slash = / [ \/ | '\\' ]  /;
    for @modules -> $f is copy {
        my $t = $f.slurp;
        while $t ~~ /^^ \s* '=begin' \s+ <ident> .* '=end' \s+ <ident> / {
            $t = $t.substr(0,$/.from) ~ $t.substr($/.to);
        }

        my $not-deps       = any(<v6 MONKEY_TYPING strict fatal nqp NativeCall cur lib>);
        my $dep-parser     = Grammar::Dependency::Parser.parse($t);

        my @depends = gather for $dep-parser.<load-statement>.list -> $dep {
            next if $dep.<short-name>.Str ~~ any($not-deps);
            take $dep.<short-name>.Str;
        }

        @minimeta.push({
            name => $f.path.subst(/^.*?<$slash>?lib<$slash>/,'').subst(/\.pm6?$/, '').subst($slash, '::', :g),
            file => $f.path,
            dependencies => @depends, 
        });
    }

    return @minimeta;
}



sub extract-deps(*@paths) is export {
    Zef::Utils::Depends.new.extract-deps(@paths);
}

sub build-dep-tree(*@metas) is export {
    Zef::Utils::Depends.new(:@metas).build-dep-tree;    
}