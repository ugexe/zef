role Zef::Role::P5Prove {
    multi method test(Str $dir) { self.test($dir.IO) }
    multi method test(IO::Path $dir) {
        shell "prove -V";
        shell "(cd $dir && prove -v -e 'perl6 -Iblib/lib -Ilib' t/)";
        say "Prove Test successful?";
    }
};

