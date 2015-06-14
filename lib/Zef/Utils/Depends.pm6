class Zef::Utils::Depends {
    has @!metas;

    submethod BUILD(:@!metas) { }

    # A poor attempt to parse module names from source code
    grammar Grammar::Dependency::Parser {
        token TOP {
            [.*? <load-statement>]+ .*? $
        }

        token load-statement { <load-type> \s+ <short-name>               }
        token short-name     { <name-piece> [<.colon-pair> <name-piece>]* }
        token name-piece     { <.name-token>+       }
        token name-token     { <+[\S] -restricted>  }
        token restricted     { < : ; { } [ ] ( ) . , = + / \ ] $ @ % ! ^ & * ~ # ` | ? > || '<' || '>' }
        token colon-pair     { '::' }

        proto token load-type {*}
        token load-type:sym<use>     { <sym> }
        token load-type:sym<need>    { <sym> }
        token load-type:sym<require> { <sym> }
    }

    # Creates a build order from a list of meta files
    method build-dep-tree(@xmetas = @!metas, :$target) {
        my @depends = $target // @xmetas // @!metas;
        my @tree = eager gather while @depends.shift -> %meta {
            state %marked;
            unless %marked.{%meta.<name>} {
                my @required = @xmetas.grep({ $_.<name> ~~ any(%meta<depends>.list) });
                my @needed   = @required.grep(-> %d { not %marked.{%d.<name>} });
                @needed.map(-> %d { @depends.unshift({ %d }) });
                @depends.push({ %meta });
                next if @needed;
            }
            take { %meta } unless %marked.{%meta.<name>}++;
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

    # Determine build order for a CompUnitRepo's provides by parsing the source
    method extract-deps(*@paths) {
        @paths //= @!metas.grep({ $_.<file> });
        my @modules = @paths.grep(*.IO.f).grep({ $_.IO.basename ~~ / \.pm6? $/ });
        my $slash = / [ \/ | '\\' ]  /;

        my @minimeta = eager gather for @modules -> $f is copy {
            my $t = $f.IO.slurp;
            while $t ~~ /^^ \s* '=begin' \s+ <ident> .* '=end' \s+ <ident> / {
                $t = $t.substr(0,$/.from) ~ $t.substr($/.to);
            }

            my $not-deps   = any(<v6 MONKEY-TYPING MONKEY_TYPING strict fatal nqp NativeCall cur lib Test>);
            my $dep-parser = Grammar::Dependency::Parser.parse($t);

            my @depends = gather for $dep-parser.<load-statement>.list -> $dep {
                next if $dep.<short-name>.Str ~~ any($not-deps);
                take $dep.<short-name>.Str;
            }

            my @splitdir    = $*SPEC.splitdir($f.IO.dirname);
            my $ext         = ".{$f.IO.extension}";
            my $base-name   = $f.IO.basename.subst(/$ext$/,'');
            my $module-name = [@splitdir[@splitdir.last-index("lib")+1..*], $base-name].join('::');

            take {
                name         => $module-name,
                path         => $f.IO.path,
                depends      => @depends, 
            }
        }

        return @minimeta;
    }

    # Not used currently. May be used to parse dependencies from an exception message.
    method runtime-extract-deps(*@paths is copy) {
        #use Perl6::Grammar:from<NQP>; # prevents compile on jvm
        #use Perl6::Actions:from<NQP>;

        @paths //= @!metas.grep({ $_.<file> });
        my @pm6-files := @paths.grep(*.IO.f).grep({ $_.IO.basename ~~ / \.pm6? $/ });

        # Try to parse exceptions for missing dependencies
        my @missing = eager gather for @pm6-files -> $source {
            try {
                my $*LINEPOSCACHE;            
                Perl6::Grammar.parse($source.IO.slurp, :actions(Perl6::Actions.new()));

                CATCH { 
                    when X::AdHoc {
                        if $_.payload ~~ /'Could not find'\s$<missing>=(.*?)\s'in any of:'/ {
                            take ~$/.<missing>;
                            # Inject fake dependency or find another way
                            # to continue on and parse more dependencies 
                            # as only one module name is shown per exception.
                        }
                    }
                }
            }
        }
    }
}

sub runtime-extract-deps(*@paths) is export {
    Zef::Utils::Depends.new.runtime-extract-deps(@paths);
}

sub extract-deps(*@paths) is export {
    Zef::Utils::Depends.new.extract-deps(@paths);
}

sub build-dep-tree(*@metas, :$target) is export {\
    Zef::Utils::Depends.new(:@metas).build-dep-tree(:$target);    
}