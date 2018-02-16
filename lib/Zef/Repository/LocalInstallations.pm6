use Zef;
use Zef::Distribution::Local;
use Zef::Distribution::DependencySpecification;

class Zef::Repository::LocalInstallations does Repository {
    has @!dists;

    method available(--> Seq) {
        my $candidates := self!gather-dists.map: -> $dist {
            Candidate.new(
                dist => $dist,
                uri  => $dist.IO.absolute,
                as   => $dist.identity,
                from => self.id,
            )
        }

        return $candidates.grep(*.so);
    }

    method search(:$max-results = 5, Bool :$strict, *@identities, *%fields --> Seq) {
        return () unless @identities || %fields;
        my %specs = @identities.map: { $_ => Zef::Distribution::DependencySpecification.new($_) }

        my $candidates := self.available.map(*.dist).map: -> $dist {
            my $matches := @identities.grep({ $dist.contains-spec(%specs{$_}, :$strict) }).map: -> $wanted-as {
                Candidate.new(
                    dist => $dist,
                    uri  => $dist.IO.absolute,
                    as   => $wanted-as,
                    from => self.id,
                );
            }
            $matches.Slip
        }

        return $candidates.grep(*.so);
    }

    method !gather-dists(*@curis) {
        @!dists = @!dists ?? @!dists !! do {
            my @curs       = +@curis ?? @curis !! $*REPO.repo-chain.grep(*.?prefix.?e);
            my @repo-dirs  = @curs>>.prefix;
            my @dist-dirs  = |@repo-dirs.map(*.child('dist')).grep(*.e);
            my @dist-files = |@dist-dirs.map(*.IO.dir.grep(*.IO.f).Slip);
            @dist-files.map({ try Zef::Distribution::Local.new($_) }).grep(*.so)
        }
        @!dists;
    }
}