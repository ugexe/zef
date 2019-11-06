use v6;
use Test;
plan 1;

use Zef;
use Zef::Extract;


subtest 'Zef::Extract.extract' => {
    subtest 'Two extracters, first does not match/handle uri' => {
        my class Mock::Extracter::One does Extractor {
            method extract-matcher(|--> False) { }

            method extract($from, $to) { die 'should not get called' }

            method ls-files { }
        }

        my class Mock::Extracter::Two does Extractor {
            method extract-matcher(|--> True) { }

            method extract($from, $to) { $to }

            method ls-files { }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $extracter = Zef::Extract.new but role :: { method plugins(|--> List) { Mock::Extracter::One.new, Mock::Extracter::Two.new } };
        is $extracter.extract(Candidate.new(:uri($*CWD)), $save-to.absolute), $save-to.absolute;
        try $save-to.rmdir;
    }

    subtest 'Two extracters, first not capable of handling given uri' => {
        my class Mock::Extracter::One does Extractor {
            method extract-matcher(|--> False) { }

            method extract($from, $to) { die 'should not get called' }

            method ls-files { }
        }

        my class Mock::Extracter::Two does Extractor {
            method extract-matcher(|--> True) { }

            method extract($from, $to) { $to }

            method ls-files { }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $extracter = Zef::Extract.new but role :: { method plugins(|--> List) { Mock::Extracter::One.new, Mock::Extracter::Two.new } };
        is $extracter.extract(Candidate.new(:uri($*CWD)), $save-to.absolute), $save-to.absolute;
        try $save-to.rmdir;
    }

    subtest 'Two extracters, first fails' => {
        my class Mock::Extracter::One does Extractor {
            method extract-matcher(|--> True) { }

            method extract($from, $to --> Nil) { }

            method ls-files { }
        }

        my class Mock::Extracter::Two does Extractor {
            method extract-matcher(|--> True) { }

            method extract($from, $to) { $to }

            method ls-files { }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $extracter = Zef::Extract.new but role :: { method plugins(|--> List) { Mock::Extracter::One.new, Mock::Extracter::Two.new } };
        is $extracter.extract(Candidate.new(:uri($*CWD)), $save-to.absolute), $save-to.absolute;
        try $save-to.rmdir;
    }

    subtest 'Two extracters, first times out' => {
        my constant timeout = 1;

        my class Mock::Extracter::One does Extractor {
            method extract-matcher(|--> True) { }

            method extract($from, $to) { sleep(timeout * 5); timeout; }

            method ls-files { }
        }

        my class Mock::Extracter::Two does Extractor {
            method extract-matcher(|--> True) { }

            method extract($from, $to) { $to }

            method ls-files { }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $extracter = Zef::Extract.new but role :: { method plugins(|--> List) { Mock::Extracter::One.new, Mock::Extracter::Two.new } };
        is $extracter.extract(Candidate.new(:uri($*CWD)), $save-to.absolute, :timeout(timeout)), $save-to.absolute;
        try $save-to.rmdir;
    }
}


done-testing;