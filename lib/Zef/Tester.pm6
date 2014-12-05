module Zef::Tester;
use Zef::Exception;

use Zef::Tester::P5Prove; # todo: pull these in like plugins


# default testing: use perl6 directly on test files
# overridden by Zef::Tester::P5Prove test method

method test(Str $dir) { $dir.IO }
method test(IO::Path $dir) {
    shell "prove -V" or 
        X::Zef.new( :stage($?MODULE), :reason('perl6 -V exited non-zero') );

    shell "(cd $dir && perl6 -Iblib/lib -Ilib t/") or
        X::Zef.new( :stage($?MODULE), :reason('Test exited non-zero') );

    say "Test successful?";    
}
