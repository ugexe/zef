use Zef::Phase::Testing;

role Zef::Plugin::P5Prove {
    also does Zef::Phase::Testing;

    multi method test(*@dirs) {
        shell "prove -V";
        my $prove = shell "(cd $*CWD && prove -v -e 'perl6 -Iblib/lib -Ilib' {~@dirs})";
    }
}

