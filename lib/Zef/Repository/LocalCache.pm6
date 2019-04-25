use Zef;
use Zef::Distribution::Local;
use Zef::Distribution::DependencySpecification;
use Zef::Utils::FileSystem;

# Intended to:
# 1) Keep track of contents of a directory using a manifest.
#   a) full update to recursively search location to discover everything
#   b) .store method to be called after something is fetched, allowing
#       the single entry to be added to the manifest without having to search
# 2) If a requested identity matches anything found in the manifest already
#    then it will return *that* instead of necessarily making net requests
#    for other Repository like p6c or CPAN (although such choices are
#    made inside Zef::Repository itself)
class Zef::Repository::LocalCache does Repository {
    has $.mirrors;
    has $.auto-update is rw;
    has $.cache;
    has @!dists;

    method IO(--> IO::Path) { my $dir = $!cache.IO; $dir.mkdir unless $dir.e; $dir }

    method available(--> Seq) {
        self!gather-dists.map: -> $dist {
            Candidate.new(
                dist => $dist,
                uri  => ($dist.source-url || $dist.hash<support><source>),
                from => self.id,
                as   => $dist.identity,
            );
        }
    }

    # Rebuild the manifest/index by recursively searching for META files
    method update {
        LEAVE { self.store(@!dists) }
        self!update;
        self!gather-dists;
    }

    method !update(-->Bool) {
        # $.cache/level1/level2/ # dirs containing dist files
        my @dirs    = $!cache.IO.dir.grep(*.d).map(*.dir.Slip).grep(*.d);
        my @dists   = grep { .defined }, map { try Zef::Distribution::Local.new($_) }, @dirs;
        my $content = join "\n", @dists.map: { join "\0", (.identity, .path) }
        so $content ?? self!spurt-package-list($content) !! False;
    }

    # todo: handle %fields
    # note this doesn't apply the $max-results per identity searched, and always returns a 1 dist
    # max for a single identity (todo: update to handle $max-results for each @identities)
    method search(:$max-results = 5, Bool :$strict, *@identities, *%fields --> Seq) {
        return ().Seq unless @identities || %fields;

        my %specs = @identities.map: { $_ => Zef::Distribution::DependencySpecification.new($_) }
        my @searchable-identities = %specs.classify({ .value.from-matcher })<Perl6>.grep(*.defined).hash.keys;
        return ().Seq unless @searchable-identities;

        # identities that are cached in the localcache manifest
        gather for |self!gather-dists -> $dist {
            for @searchable-identities.grep({ $dist.contains-spec(%specs{$_}, :$strict) }) -> $wanted-as {
                take Candidate.new(
                    dist => $dist,
                    uri  => $dist.IO.absolute,
                    as   => $wanted-as,
                    from => self.id,
                );
            }
        }
    }

    # After the `fetch` phase an app can call `.store` on any Repository that
    # provides it, allowing each Repository to do things like keep a simple list of
    # identities installed, keep a cache of anything installed (how its used here), etc
    method store(*@new --> Bool) {
        for @new.unique(:as(*.identity)).map(*.IO.parent.IO).unique -> $from {
            try copy-paths( $from, $.cache.IO.child($from.basename) )
        }
        self!update;
    }

    method !package-list-path(--> IO::Path)  {
        my $path = self.IO.child('MANIFEST.zef');
        $path.spurt('') unless $path.e;
        $path;
    }

    method !slurp-package-list(--> List) {
        return [ ] unless self!package-list-path.e;

        do given self!package-list-path.open(:r) {
            LEAVE {.close}
            .lock: :shared;
            .slurp.lines.map({.split("\0")[1]}).cache;
        }
    }

    method !spurt-package-list($content --> Bool) {
        do given self!package-list-path.open(:w) {
            LEAVE {.close}
            .lock;
            try .spurt($content);
        }
    }

    # Abstraction to handle automatic updating of package list and/or local index
    method !gather-dists(--> List) {
        once { self.update } if $.auto-update || !self!package-list-path.e;
        return @!dists if +@!dists;

        @!dists = gather for self!slurp-package-list.grep(*.IO.e) -> $path {
            take($_) with try Zef::Distribution::Local.new($path);
        }
    }
}
