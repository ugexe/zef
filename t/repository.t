use Test:ver<6.c+>;
plan 1;

use Zef;
use Zef::Distribution;
use Zef::Repository;


subtest 'Zef::Repository.candidates' => {
    my class Mock::Repository::One does PackageRepository {
        method fetch-matcher(|--> True ) { }

        method search(*@_) {
            return Empty unless @_.any ~~ 'Foo::Quick';
            my Candidate @candidates =
                Candidate.new(
                    dist => Zef::Distribution.new(:name('Foo::Quick'), :ver<0>, :api<1>,),
                    as   => 'Foo::Quick',
                ),
                Candidate.new(
                    dist => Zef::Distribution.new(:name('Foo::Quick'), :ver<0.1>, :api<2>),
                    as   => 'Foo::Quick',
                ),
                Candidate.new(
                    dist => Zef::Distribution.new(:name('Foo::Quick'), :ver<0.2>, :api<1>),
                    as   => 'Foo::Quick',
                );
            return @candidates;
        }
    }

    my class Mock::Repository::Two does PackageRepository {
        method fetch-matcher(|--> True) { }

        method search(*@_) {
            return Empty unless @_.any ~~ 'Foo::Quick';
            my Candidate @candidates =
                Candidate.new(
                    dist => Zef::Distribution.new(:name('Foo::Quick'), :ver<0.3>,),
                    as   => 'Foo::Quick',
                ),
                Candidate.new(
                    dist => Zef::Distribution.new(:name('Foo::Quick'), :ver<0>,),
                    as   => 'Foo::Quick',
                ),
                Candidate.new(
                    dist => Zef::Distribution.new(:name('Foo::Quick'), :ver<0>, :auth<B>),
                    as   => 'Foo::Quick',
                );
            return @candidates;
        }
    }

    my class Mock::Repository::Three does PackageRepository {
        method fetch-matcher(|--> True) { }

        method search(*@_) {
            return Empty unless @_.any ~~ 'Bar';
            my Candidate @candidates =
                Candidate.new(
                    dist => Zef::Distribution.new(:name('Bar'), :ver<0.1>,),
                    as   => 'Bar',
                );
            return @candidates;
        }
    }

    subtest 'api + version sorting' => {
        {
            my $zef-repository = Zef::Repository.new but role :: { method plugins(|--> List) { [[Mock::Repository::One.new, Mock::Repository::Two.new],] } };
            my @candidates = $zef-repository.candidates('Foo::Quick');
            is @candidates.elems, 1, 'Results are grouped by Candidate.as';
            is @candidates.head.dist.ver, v0.1, 'Results return sorted from highest api/ver to lowest';
        }

        # Like the previous test, but switching the order of the plugins
        {
            my $zef-repository = Zef::Repository.new but role :: { method plugins(|--> List) { [[Mock::Repository::Two.new, Mock::Repository::One.new],] } };
            my @candidates = $zef-repository.candidates('Foo::Quick');
            is @candidates.elems, 1, 'Results are grouped by Candidate.as';
            is @candidates.head.dist.ver, v0.1, 'Results return sorted from highest api/ver to lowest';
        }
    }

    subtest 'tiered ecosystems with api + version sorting' => {
        {
            my $zef-repository = Zef::Repository.new but role :: {
                method plugins(|--> List) {
                    [
                        [Mock::Repository::One.new,],
                        [Mock::Repository::Two.new, Mock::Repository::Three.new],
                    ]
                }
            }
            my @candidates = $zef-repository.candidates('Foo::Quick','Bar');
            is @candidates.elems, 2, 'Results are grouped by Candidate.as';

            my $foo-dist = @candidates.first({ .dist.name eq 'Foo::Quick' }).dist;
            ok $foo-dist, 'Found correct dist';
            is $foo-dist.ver, v0.1, 'Found correct dist';

            my $bar-dist = @candidates.first({ .dist.name eq 'Bar' }).dist;
            ok $bar-dist, 'Results return sorted from highest api/ver to lowest from first tier with any matches';
            is $bar-dist.ver, v0.1, 'Results return sorted from highest api/ver to lowest from first tier with any matches';
        }

        # Like the previous test, but switching the order of the plugins
        {
            my $zef-repository = Zef::Repository.new but role :: {
                method plugins(|--> List) {
                    [
                        [Mock::Repository::Two.new, Mock::Repository::Three.new],
                        [Mock::Repository::One.new,],
                    ]
                }
            };
            my @candidates = $zef-repository.candidates('Foo::Quick','Bar');
            is @candidates.elems, 2, 'Results are grouped by Candidate.as';

            my $foo-dist = @candidates.first({ .dist.name eq 'Foo::Quick' }).dist;
            ok $foo-dist, 'Found correct dist';
            is $foo-dist.ver, v0.3, 'Found correct dist';

            my $bar-dist = @candidates.first({ .dist.name eq 'Bar' }).dist;
            ok $bar-dist, 'Results return sorted from highest api/ver to lowest from first tier with any matches';
            is $bar-dist.ver, v0.1, 'Results return sorted from highest api/ver to lowest from first tier with any matches';
        }
    }
}


done-testing;