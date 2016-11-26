use v6;
use Test;
plan 3;

use Zef::ContentStorage;
use Zef::ContentStorage::Ecosystems;
use Zef::Fetch;


subtest {
    class Mock::ContentStorage does ContentStorage {
        method search(:$max-results = 5, *@identities, *%fields) {
            @ = Candidate.new(:as("{@identities[0]}::X")),
                Candidate.new(:as("{@identities[0]}::XX"));
        }
    }

    subtest {
        my $mock-storage = Mock::ContentStorage.new;
        my @candidates   = $mock-storage.search("Mock::Storage");

        is +@candidates, 2;
        is @candidates[0].as, "Mock::Storage::X";
        is @candidates[1].as, "Mock::Storage::XX";
    }, "Mock::ContentStorage";

    subtest {
        my $mock-storage1 = Mock::ContentStorage.new;
        my $mock-storage2 = Mock::ContentStorage.new;
        my $content-storage = Zef::ContentStorage.new but role :: {
            method plugins { state @plugins = $mock-storage1, $mock-storage2 }
        }
        my @candidates = $content-storage.search("Mock::Storage");
        is +@candidates, 4;
        is @candidates[0].as, "Mock::Storage::X";
        is @candidates[1].as, "Mock::Storage::XX";
        is @candidates[2].as, "Mock::Storage::X";
        is @candidates[3].as, "Mock::Storage::XX";
    }, 'Zef::ContentStorage service aggregation'
}, "ContentStorage";


subtest {
    my $wanted   = 'Base64';
    my @mirrors  = 'git://github.com/ugexe/Perl6-ecosystems.git';
    my @backends = [
        { module => "Zef::Service::Shell::git" },
        { module => "Zef::Service::Shell::wget" },
        { module => "Zef::Service::Shell::curl" },
        { module => "Zef::Service::Shell::PowerShell::download" },
    ];

    my $fetcher = Zef::Fetch.new(:@backends);
    my $p6c     = Zef::ContentStorage::Ecosystems.new(name => 'p6c', :auto-update, :@mirrors);
    $p6c.fetcher //= $fetcher;
    $p6c.cache   //= $*HOME.child('.zef/store').absolute;
    ok $p6c.available > 0;

    subtest {
        my @candidates = $p6c.search('Base64', :strict);
        ok +@candidates > 0;
        is @candidates.grep({ .dist.name ne $wanted }).elems, 0;
    }, 'search';
}, "Ecosystems => p6c";


subtest {
    my $wanted   = 'P6TCI';
    my @mirrors  = 'https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan.json';
    my @backends = [
        { module => "Zef::Service::Shell::wget" },
        { module => "Zef::Service::Shell::curl" },
        { module => "Zef::Service::Shell::PowerShell::download" },
    ];

    my $fetcher = Zef::Fetch.new(:@backends);
    my $cpan    = Zef::ContentStorage::Ecosystems.new(name => 'cpan', :auto-update, :@mirrors);
    $cpan.fetcher //= $fetcher;
    $cpan.cache   //= $*HOME.child('.zef/store').absolute;
    ok $cpan.available > 0;

    subtest {
        my @candidates = $cpan.search('P6TCI', :strict);
        ok +@candidates > 0;
        is @candidates.grep({ .dist.name ne $wanted }).elems, 0;
    }, 'search';
}, "Ecosystems => cpan";


done-testing;