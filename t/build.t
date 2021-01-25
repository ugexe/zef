use v6;
use Test;
plan 1;

use Zef;
use Zef::Build;
use Zef::Distribution;


subtest 'Zef::Build.build' => {
    subtest 'Two builders, first does not match/handle uri' => {
        my class Mock::Builder::One does Builder {
            method build-matcher(|--> False) { }

            method build($) { die 'should not get called' }
        }

        my class Mock::Builder::Two does Builder {
            method build-matcher(|--> True) { }

            method build($ --> True) { }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $builder = Zef::Build.new but role :: { method plugins(|--> List) { Mock::Builder::One.new, Mock::Builder::Two.new } };
        my $dist    = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        ok $builder.build(Candidate.new(:$dist));
        try $save-to.rmdir;
    }

    subtest 'Two builders, first not capable of handling given uri' => {
        my class Mock::Builder::One does Builder {
            method build-matcher(|--> False) { }

            method build($) { die 'should not get called' }
        }

        my class Mock::Builder::Two does Builder {
            method build-matcher(|--> True) { }

            method build($ --> True) { }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $builder = Zef::Build.new but role :: { method plugins(|--> List) { Mock::Builder::One.new, Mock::Builder::Two.new } };
        my $dist    = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        ok $builder.build(Candidate.new(:$dist));
        try $save-to.rmdir;
    }

    subtest 'Two builders, first fails' => {
        my class Mock::Builder::One does Builder {
            method build-matcher(|--> True) { }

            method build($ --> Nil) { }
        }

        my class Mock::Builder::Two does Builder {
            method build-matcher(|--> True) { }

            method build($ --> True) { }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $builder = Zef::Build.new but role :: { method plugins(|--> List) { Mock::Builder::One.new, Mock::Builder::Two.new } };
        my $dist    = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        ok $builder.build(Candidate.new(:$dist));
        try $save-to.rmdir;
    }

    subtest 'Two builders, first times out' => {
        my constant timeout = 1;

        my class Mock::Builder::One does Builder {
            method build-matcher(|--> True) { }

            method build($) { sleep(timeout * 5); timeout; }
        }

        my class Mock::Builder::Two does Builder {
            method build-matcher(|--> True) { }

            method build($ --> True) { }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $builder = Zef::Build.new but role :: { method plugins(|--> List) { Mock::Builder::One.new, Mock::Builder::Two.new } };
        my $dist    = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        ok $builder.build(Candidate.new(:$dist), :timeout(timeout));
        try $save-to.rmdir;
    }
}


done-testing;