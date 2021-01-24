use v6;
use Test;
plan 1;

use Zef;
use Zef::Fetch;


subtest 'Zef::Fetch.fetch' => {
    subtest 'Two fetchers, first does not match/handle uri' => {
        my class Mock::Fetcher::One does Fetcher {
            method fetch-matcher(|--> False) { }

            method fetch($, $) { die 'should not get called' }
        }

        my class Mock::Fetcher::Two does Fetcher {
            method fetch-matcher(|--> True) { }

            method fetch($, $to) { $to }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $fetcher = Zef::Fetch.new but role :: { method plugins(|--> List) { Mock::Fetcher::One.new, Mock::Fetcher::Two.new } };
        is $fetcher.fetch(Candidate.new(:uri($*CWD)), $save-to.absolute), $save-to.absolute;
        try $save-to.rmdir;
    }

    subtest 'Two fetchers, first not capable of handling given uri' => {
        my class Mock::Fetcher::One does Fetcher {
            method fetch-matcher(|--> False) { }

            method fetch($, $) { die 'should not get called' }
        }

        my class Mock::Fetcher::Two does Fetcher {
            method fetch-matcher(|--> True) { }

            method fetch($, $to) { $to }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $fetcher = Zef::Fetch.new but role :: { method plugins(|--> List) { Mock::Fetcher::One.new, Mock::Fetcher::Two.new } };
        is $fetcher.fetch(Candidate.new(:uri($*CWD)), $save-to.absolute), $save-to.absolute;
        try $save-to.rmdir;
    }

    subtest 'Two fetchers, first fails' => {
        my class Mock::Fetcher::One does Fetcher {
            method fetch-matcher(|--> True) { }

            method fetch($, $ --> Nil) { }
        }

        my class Mock::Fetcher::Two does Fetcher {
            method fetch-matcher(|--> True) { }

            method fetch($, $to) { $to }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $fetcher = Zef::Fetch.new but role :: { method plugins(|--> List) { Mock::Fetcher::One.new, Mock::Fetcher::Two.new } };
        is $fetcher.fetch(Candidate.new(:uri($*CWD)), $save-to.absolute), $save-to.absolute;
        try $save-to.rmdir;
    }

    subtest 'Two fetchers, first times out' => {
        my constant timeout = 1;

        my class Mock::Fetcher::One does Fetcher {
            method fetch-matcher(|--> True) { }

            method fetch($, $) { sleep(timeout * 5); timeout; }
        }

        my class Mock::Fetcher::Two does Fetcher {
            method fetch-matcher(|--> True) { }

            method fetch($, $to) { $to }
        }

        my $save-to = $*TMPDIR.child(100000.rand).mkdir;
        my $fetcher = Zef::Fetch.new but role :: { method plugins(|--> List) { Mock::Fetcher::One.new, Mock::Fetcher::Two.new } };
        is $fetcher.fetch(Candidate.new(:uri($*CWD)), $save-to.absolute, :timeout(timeout)), $save-to.absolute;
        try $save-to.rmdir;
    }
}


done-testing;