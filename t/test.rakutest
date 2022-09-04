use Test:ver<6.c+>;
plan 1;

use Zef;
use Zef::Test;
use Zef::Distribution;


subtest 'Zef::Test.test' => {
    subtest 'Two testers, first does not match/handle uri' => {
        my class Mock::Tester::One does Tester {
            method test-matcher(|--> False) { }

            method test($) { die 'should not get called' }
        }

        my class Mock::Tester::Two does Tester {
            method test-matcher(|--> True) { }

            method test($ --> True) { }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $tester  = Zef::Test.new but role :: { method plugins(|--> List) { Mock::Tester::One.new, Mock::Tester::Two.new } };
        my $dist    = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        ok $tester.test(Candidate.new(:$dist));
        try $save-to.rmdir;
    }

    subtest 'Two testers, first not capable of handling given uri' => {
        my class Mock::Tester::One does Tester {
            method test-matcher(|--> False) { }

            method test($) { die 'should not get called' }
        }

        my class Mock::Tester::Two does Tester {
            method test-matcher(|--> True) { }

            method test($ --> True) { }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $tester  = Zef::Test.new but role :: { method plugins(|--> List) { Mock::Tester::One.new, Mock::Tester::Two.new } };
        my $dist    = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        ok $tester.test(Candidate.new(:$dist));
        try $save-to.rmdir;
    }

    subtest 'Two testers, first fails and second is not tried' => {
        my class Mock::Tester::One does Tester {
            method test-matcher(|--> True) { }

            method test($ --> Nil) { }
        }

        my class Mock::Tester::Two does Tester {
            method test-matcher(|--> True) { }

            method test($ --> True) { die 'should not get called' }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $tester  = Zef::Test.new but role :: { method plugins(|--> List) { Mock::Tester::One.new, Mock::Tester::Two.new } };
        my $dist    = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        is $tester.test(Candidate.new(:$dist)).grep(*.so).elems, 0;
        try $save-to.rmdir;
    }

    subtest 'Two testers, first times out and second is not tried' => {
        my constant timeout = 1;

        my class Mock::Tester::One does Tester {
            method test-matcher(|--> True) { }

            method test($) { sleep(timeout * 5); timeout; }
        }

        my class Mock::Tester::Two does Tester {
            method test-matcher(|--> True) { }

            method test($ --> True) { die 'should not get called' }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $tester  = Zef::Test.new but role :: { method plugins(|--> List) { Mock::Tester::One.new, Mock::Tester::Two.new } };
        my $dist    = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        is $tester.test(Candidate.new(:$dist), :timeout(timeout)).grep(*.so).elems, 0;
        try $save-to.rmdir;
    }
}


done-testing;