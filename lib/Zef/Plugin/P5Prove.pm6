use Zef::Phase::Testing;
role Zef::Plugin::P5Prove does Zef::Phase::Testing {
    multi method test(*@dirs) {
        my $cmd = 
            "prove -V && "
           ~"(cd $*CWD && "
               ~"prove -v -e '"
                   ~"perl6 -Iblib/lib -Ilib"
                   ~"' {~@dirs} )";

        shell($cmd).exit == 0 ?? True  !! False;
    }
}
