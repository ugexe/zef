module Zef::Tester::P5Prove;

role Prove[::Zef::Tester] {
    proto method test() {*}
    multi method test(Str $dir) { self.test($dir.IO) }
    multi method test(IO::Path $dir) does proves {
        shell "prove -V";
        shell "(cd $dir && prove -v -e 'perl6 -Iblib/lib -Ilib' t/");
        say "Prove Test successful?";
    }
}

