use v6;
use Test;
plan 2;

use Zef::ContentStorage::P6C;
use Zef::Fetch;


subtest {
    my $wanted   = 'Base64';
    my @mirrors  = 'git://github.com/ugexe/Perl6-ecosystems.git';
    my @backends = [
        { module => "Zef::Service::Shell::git" },
    ];

    my $fetcher = Zef::Fetch.new(:@backends);
    my $p6c     = Zef::ContentStorage::P6C.new(:@mirrors);
    $p6c.fetcher //= $fetcher;
    $p6c.cache   //= $*HOME.child('.zef/store').absolute;
    ok $p6c.available > 0;

    subtest {
        my @candidates = $p6c.search('Base64');
        ok +@candidates > 0;
        is @candidates.grep({ .dist.name ne $wanted }).elems, 0;
    }, 'search';
}, "P6C";


subtest {
    my $wanted   = 'Base64';
    my @mirrors  = 'http://hack.p6c.org:5000/v0/release/';
    my @backends = [
        { module => "Zef::Service::Shell::wget" },
        { module => "Zef::Service::Shell::curl" },
        { module => "Zef::Service::Shell::PowerShell::download" },
    ];

    my $fetcher = Zef::Fetch.new(:@backends);
    my $cpan    = Zef::ContentStorage::P6C.new(:@mirrors);
    $cpan.fetcher //= $fetcher;
    $cpan.cache   //= $*HOME.child('.zef/store').absolute;
    ok $cpan.available > 0;

    subtest {
        my @candidates = $cpan.search('Base64');
        ok +@candidates > 0;
        is @candidates.grep({ .dist.name ne $wanted }).elems, 0;
    }, 'search';
}, "CPAN";


done-testing;