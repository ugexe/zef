module Zef::Tester::P5Prove is Zef::Tester;
use Zef::Exception;


multi method test(Str $dir) { self.test($dir.IO) }
multi method test(IO::Path $dir) does proves {
    prove($dir);
}

role proves {
    method prove(IO::Path $dir) {
        shell "prove -V" or 
            X::Zef.new( :stage($?MODULE), :reason('prove -V exited non-zero') );

        shell "(cd $dir && prove -v -e 'perl6 -Iblib/lib -Ilib' t/") or
            X::Zef.new( :stage($?MODULE), :reason('prove testing exited non-zero') );

        say "Test successful?";
    }
}
