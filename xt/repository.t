use v6;
use Test;
plan 3;

use Zef;
use Zef::Repository;
use Zef::Repository::Ecosystems;
use Zef::Fetch;


subtest {
    class Mock::Repository does Repository {
        method search(:$max-results = 5, *@identities, *%fields) {
            my @candidates =
                Candidate.new(:as("{@identities[0]}::X")),
                Candidate.new(:as("{@identities[0]}::XX"));
        }
    }

    subtest {
        my $mock-repository = Mock::Repository.new;
        my @candidates   = $mock-repository.search("Mock::Repository");

        is +@candidates, 2;
        is @candidates[0].as, "Mock::Repository::X";
        is @candidates[1].as, "Mock::Repository::XX";
    }, "Mock::Repository";

    subtest {
        my $mock-repository1 = Mock::Repository.new;
        my $mock-repository2 = Mock::Repository.new;
        my $repository = Zef::Repository.new but role :: {
            method plugins { state @plugins = $mock-repository1, $mock-repository2 }
        }
        my @candidates = $repository.search("Mock::Repository");
        is +@candidates, 4;
        is @candidates[0].as, "Mock::Repository::X";
        is @candidates[1].as, "Mock::Repository::XX";
        is @candidates[2].as, "Mock::Repository::X";
        is @candidates[3].as, "Mock::Repository::XX";
    }, 'Zef::Repository service aggregation'
}, "Repository";


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
    my $p6c     = Zef::Repository::Ecosystems.new(name => 'p6c', :auto-update, :@mirrors);
    $p6c.fetcher //= $fetcher;
    $p6c.cache   //= $*HOME.child('.zef/store').absolute andthen { mkdir $_ unless $_.IO.e };
    ok $p6c.available > 0;

    subtest {
        my @candidates = $p6c.search('Base64', :strict);
        ok +@candidates > 0;
        is @candidates.grep({ .dist.name ne $wanted }).elems, 0;
    }, 'search';
}, "Ecosystems => p6c";


subtest {
    my $wanted   = 'P6TCI';
    my @mirrors  = 'https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/667d2f0c6f9f43dfd05926c561e828b06dc2bf23/cpan.json';
    my @backends = [
        { module => "Zef::Service::Shell::wget" },
        { module => "Zef::Service::Shell::curl" },
        { module => "Zef::Service::Shell::PowerShell::download" },
    ];

    my $fetcher = Zef::Fetch.new(:@backends);
    my $cpan    = Zef::Repository::Ecosystems.new(name => 'cpan', :auto-update, :@mirrors);
    $cpan.fetcher //= $fetcher;
    $cpan.cache   //= $*HOME.child('.zef/store').absolute andthen { mkdir $_ unless $_.IO.e };
    ok $cpan.available > 0;

    subtest {
        my @candidates = $cpan.search('P6TCI', :strict);
        ok +@candidates > 0;
        is @candidates.grep({ .dist.name ne $wanted }).elems, 0;
    }, 'search';
}, "Ecosystems => cpan";


done-testing;