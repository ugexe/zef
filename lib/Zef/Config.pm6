use Zef;
unit module Zef::Config;

our sub parse-file($path) {
    my %config = %(from-json( $path.IO.slurp ));

    %config{$_.key} = $_.value.subst(/'{$*HOME}' || '$*HOME'/, $*HOME // $*TMPDIR, :g)\
        for %config.grep(*.key.ends-with('Dir'));

    %config<DefaultCUR> //= 'auto';

    # XXX: config upgrade - just remove this in future when no one is looking
    %config<Repository> //= %config<ContentStorage>:delete;

    %config;
}

our sub guess-path {
    my %default-conf;
    my IO::Path $local-conf-path;
    my @path-candidates = (
        (%*ENV<XDG_CONFIG_HOME> // "$*HOME/.config").IO.child('/zef/config.json'),
        %?RESOURCES<config.json>.IO,
    );
    for @path-candidates -> $path {
        if $path.e {
            %default-conf = try { parse-file($path) } // Hash.new;
            die "Failed to parse the zef config file '$path'" if !%default-conf;
            $local-conf-path = $path;
            last;
        }
    }
    die "Failed to find the zef config file at: {@path-candidates.join(', ')}"
        unless $local-conf-path.defined and $local-conf-path.e;
    die "Failed to parse a zef config file at $local-conf-path"
        if !%default-conf;
    return $local-conf-path;
}

our sub plugin-lookup($config) {
    my $lookup;
    my sub do-lookup($node) {
        if $node ~~ Hash {
            for @$node -> $sub-node {
                if $sub-node.value ~~ Str | Int && $sub-node.key eq any(<short-name module>) {
                    $lookup{$sub-node.value}.push($node);
                    next;
                }
                do-lookup($sub-node.value);
            }
        }
        elsif $node ~~ Array {
            do-lookup($_) for $node.cache;
        }
    }
    do-lookup($config);
    $lookup;
}
