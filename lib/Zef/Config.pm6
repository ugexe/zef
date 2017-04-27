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
    my $default-conf-path = %?RESOURCES<config.json>.IO;

    my %default-conf = try { parse-file($default-conf-path)    }\
                    || try { parse-file($*HOME.child('.zef'))  }\
                    || die "Failed to find the zef config file";

    my $local-conf-path = %default-conf<RootDir>.IO.child('config.json');

    return $local-conf-path   if $local-conf-path.e;
    return $default-conf-path if $default-conf-path.e;

    die "Failed to find a zef config file at {$local-conf-path} or {$default-conf-path}";
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
