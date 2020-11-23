use v6;
use Test;
plan 1;

use Zef;
use Zef::Install;
use Zef::Distribution;

my $cur = (class :: does CompUnit::Repository { method need { }; method loaded { }; method id { } }).new;

subtest 'Zef::Install.install' => {
    subtest 'Two installers, first does not match/handle uri' => {
        my class Mock::Installer::One does Installer {
            method install-matcher(|--> False) { }

            method install($candi) { die 'should not get called' }
        }

        my class Mock::Installer::Two does Installer {
            method install-matcher(|--> True) { }

            method install($candi --> True) { }
        }

        my $save-to   = $*TMPDIR.child(100000.rand).mkdir;
        my $installer = Zef::Install.new but role :: { method plugins(|--> List) { Mock::Installer::One.new, Mock::Installer::Two.new } };
        my $dist      = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        ok $installer.install(Candidate.new(:$dist), :$cur);
        try $save-to.rmdir;
    }

    subtest 'Two installers, first not capable of handling given uri' => {
        my class Mock::Installer::One does Installer {
            method install-matcher(|--> False) { }

            method install($candi) { die 'should not get called' }
        }

        my class Mock::Installer::Two does Installer {
            method install-matcher(|--> True) { }

            method install($candi --> True) { }
        }

        my $save-to   = $*TMPDIR.child(100000.rand).mkdir;
        my $installer = Zef::Install.new but role :: { method plugins(|--> List) { Mock::Installer::One.new, Mock::Installer::Two.new } };
        my $dist      = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        ok $installer.install(Candidate.new(:$dist), :$cur);
        try $save-to.rmdir;
    }

    subtest 'Two installers, first fails and second is not tried' => {
        my class Mock::Installer::One does Installer {
            method install-matcher(|--> True) { }

            method install($candi --> False) { }
        }

        my class Mock::Installer::Two does Installer {
            method install-matcher(|--> True) { }

            method install($candi --> True) { die 'should not get called' }
        }

        my $save-to   = $*TMPDIR.child(100000.rand).mkdir;
        my $installer = Zef::Install.new but role :: { method plugins(|--> List) { Mock::Installer::One.new, Mock::Installer::Two.new } };
        my $dist      = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        nok $installer.install(Candidate.new(:$dist), :$cur);
        try $save-to.rmdir;
    }

    subtest 'Two installers, first times out and second is not tried' => {
        my constant timeout = 1;

        my class Mock::Installer::One does Installer {
            method install-matcher(|--> True) { }

            method install($candi) { sleep(timeout * 5); timeout; }
        }

        my class Mock::Installer::Two does Installer {
            method install-matcher(|--> True) { }

            method install($candi --> True) { die 'should not get called' }
        }

        my $save-to   = $*TMPDIR.child(100000.rand).mkdir;
        my $installer = Zef::Install.new but role :: { method plugins(|--> List) { Mock::Installer::One.new, Mock::Installer::Two.new } };
        my $dist      = Zef::Distribution.new(:name<Foo::Bar>) but role :: { method path { $save-to } };
        nok $installer.install(Candidate.new(:$dist), :$cur, :timeout(timeout));
        try $save-to.rmdir;
    }
}


done-testing;