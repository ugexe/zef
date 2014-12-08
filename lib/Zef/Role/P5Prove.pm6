role Zef::Role::P5Prove is export {
    multi method test(*@dirs) {
        shell "prove -V";
        my $prove = shell "(cd $*CWD && prove -v -e 'perl6 -Iblib/lib -Ilib' {~@dirs})";
    }
};

