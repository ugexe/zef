use v6;
use Test;
plan 1;

use Zef;
use Zef::Distribution;
use Zef::Repository;


subtest 'Zef::Repository.candidates' => {
    subtest 'api + version sorting' => {
        my class Mock::Repository::One does PackageRepository {
            method fetch-matcher(|--> True ) { }

            method search(*@ [$short-name]) {
                my Candidate @candidates =
                    Candidate.new(
                        dist => Zef::Distribution.new(:name($short-name ~ '::Quick'), :ver<0>, :api<1>,),
                        as   => $short-name,
                    ),
                    Candidate.new(
                        dist => Zef::Distribution.new(:name($short-name ~ '::Quick'), :ver<0.1>, :api<2>),
                        as   => $short-name,
                    ),
                    Candidate.new(
                        dist => Zef::Distribution.new(:name($short-name ~ '::Fast'), :ver<0.2>, :api<1>),
                        as   => $short-name,
                    );
                return @candidates;
            }
        }

        my class Mock::Repository::Two does PackageRepository {
            method fetch-matcher(|--> True) { }

            method search(*@ [$short-name]) {
                my Candidate @candidates =
                    Candidate.new(
                        dist => Zef::Distribution.new(:name($short-name ~ '::Fast'), :ver<0.3>,),
                        as   => $short-name,
                    ),
                    Candidate.new(
                        dist => Zef::Distribution.new(:name($short-name ~ '::Quick'), :ver<0>,),
                        as   => $short-name,
                    ),
                    Candidate.new(
                        dist => Zef::Distribution.new(:name($short-name ~ '::Quick'), :ver<0>, :auth<B>),
                        as   => $short-name,
                    );
                return @candidates;
            }
        }

        my $zef-repository = Zef::Repository.new but role :: { method plugins(|--> List) { Mock::Repository::One.new, Mock::Repository::Two.new } };
        my @candidates = $zef-repository.candidates('Foo');
        is @candidates.elems, 1, 'Results are grouped by Candidate.as';
        is @candidates.head.dist.ver, v0.1, 'Results return sorted from highest api/ver to lowest';

        # Like the previous test, but switching the order of the plugins
        {
            temp $zef-repository = Zef::Repository.new but role :: { method plugins(|--> List) { Mock::Repository::Two.new, Mock::Repository::One.new } };
            is @candidates.head.dist.ver, v0.1, 'Results return sorted from highest api/ver to lowest';
        }
    }
}


done-testing;