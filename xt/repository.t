use v6;
use Test;
plan 4;

use Zef;
use Zef::Repository;
use Zef::Repository::Ecosystems;
use Zef::Fetch;


subtest 'Repository' => {
    class Mock::Repository does PackageRepository {
        method search(*@identities) {
            my Candidate @candidates =
                Candidate.new(:as("{@identities[0]}::X")),
                Candidate.new(:as("{@identities[0]}::XX"));
            return @candidates;
        }
    }

    subtest 'Mock::Repository' => {
        my $mock-repository = Mock::Repository.new;
        my @candidates   = $mock-repository.search("Mock::Repository");

        is +@candidates, 2;
        is @candidates[0].as, "Mock::Repository::X";
        is @candidates[1].as, "Mock::Repository::XX";
    }

    subtest 'Zef::Repository service aggregation' => {
        my $mock-repository1 = Mock::Repository.new;
        my $mock-repository2 = Mock::Repository.new;
        my $repository = Zef::Repository.new but role :: {
            method plugins { [[$mock-repository1, $mock-repository2],] }
        }
        my @candidates = $repository.search("Mock::Repository");
        is +@candidates, 4;
        is @candidates[0].as, "Mock::Repository::X";
        is @candidates[1].as, "Mock::Repository::XX";
        is @candidates[2].as, "Mock::Repository::X";
        is @candidates[3].as, "Mock::Repository::XX";
    }
}


subtest 'Ecosystems => p6c' => {
    my $wanted   = 'zef';
    my @mirrors  = 'git://github.com/ugexe/Perl6-ecosystems.git';
    my @backends = [
        { module => "Zef::Service::Shell::git" },
        { module => "Zef::Service::Shell::wget" },
        { module => "Zef::Service::Shell::curl" },
        { module => "Zef::Service::Shell::PowerShell::download" },
    ];

    my $fetcher = Zef::Fetch.new(:@backends);
    my $cache   = $*HOME.child('.zef/store') andthen { mkdir $_ unless $_.IO.e };
    my $p6c     = Zef::Repository::Ecosystems.new(name => 'p6c', :$fetcher, :$cache, :auto-update, :@mirrors);
    ok $p6c.available > 0;

    subtest 'search' => {
        my @candidates = $p6c.search($wanted, :strict);
        ok +@candidates > 0;
        is @candidates.grep({ .dist.name ne $wanted }).elems, 0;
    }
}


subtest  'Ecosystems => cpan' => {
    my $wanted   = 'zef';
    my @mirrors  = 'https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/11efd9077b398df3766eaa7cf8e6a9519f63c272/cpan.json';
    my @backends = [
        { module => "Zef::Service::Shell::wget" },
        { module => "Zef::Service::Shell::curl" },
        { module => "Zef::Service::Shell::PowerShell::download" },
    ];

    my $fetcher = Zef::Fetch.new(:@backends);
    my $cache   = $*HOME.child('.zef/store') andthen { mkdir $_ unless $_.IO.e };
    my $cpan    = Zef::Repository::Ecosystems.new(name => 'cpan', :$fetcher, :$cache, :auto-update, :@mirrors);
    ok $cpan.available > 0;

    subtest 'search' => {
        my @candidates = $cpan.search($wanted, :strict);
        ok +@candidates > 0;
        is @candidates.grep({ .dist.name ne $wanted }).elems, 0;
    }
}


subtest  'Ecosystems => fez' => {
    my $wanted   = 'fez';
    my @mirrors  = 'http://360.zef.pm/';
    my @backends = [
        { module => "Zef::Service::Shell::wget" },
        { module => "Zef::Service::Shell::curl" },
        { module => "Zef::Service::Shell::PowerShell::download" },
    ];

    my $fetcher = Zef::Fetch.new(:@backends);
    my $cache   = $*HOME.child('.zef/store') andthen { mkdir $_ unless $_.IO.e };
    my $fez    = Zef::Repository::Ecosystems.new(name => 'fez', :$fetcher, :$cache, :auto-update, :@mirrors);
    ok $fez.available > 0;

    subtest 'search' => {
        my @candidates = $fez.search($wanted, :strict);
        ok +@candidates > 0;
        is @candidates.grep({ .dist.name ne $wanted }).elems, 0;
    }
}


done-testing;