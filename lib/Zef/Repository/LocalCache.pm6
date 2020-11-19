use Zef;
use Zef::Distribution::Local;
use Zef::Distribution::DependencySpecification;
use Zef::Utils::FileSystem;

# The 'Repository' zef uses for its local cache
# Intended to keep track of contents of a directory using a manifest.
#   *) full update to recursively search location to discover everything
#   *) .store method to be called after something is fetched, allowing
#       the single entry to be added to the manifest without having to search
#
# NOTE: THIS IS PROBABLY NOT ANY MORE EFFICIENT THAN ::Ecosystems BASED REPOSITORIES
# At one time json parsing/writing was slow enough that parts of this implementation were faster.
# Now it is mostly just useful for dynamically generating the MANIFEST.zef from the directory
# structure this repository expects instead of fetching a file like ::Ecosystems.

class Zef::Repository::LocalCache does Repository {
    # One or more URIs containing an ecosystem 'array-of-hash' database. URI types that work
    # are whatever the supplied $!fetcher supports (so generally local files and https)
    has List $.mirrors;

    # Int | Bool
    # Int - the db will be lazily updated when it is $!auto-update hours old
    # Bool True - the db will be lazily updated regardless of how old the db is
    # Bool False - do not update the db
    has $.auto-update is rw;

    # Where we will save/stage the db file we fetch
    # TODO: coerce to IO::Path
    has Str $.cache;

    # A array of distributions found in the ecosystem db. Lazily populated as soon as the db is referenced
    has Zef::Distribution @!distributions;

    # Similar to @!distributions, but indexes by short name i.e. { "Foo::Bar" => ($dist1, $dist2), "Baz" => ($dist1) }
    has Array[Distribution] %!short-name-lookup;

    # see role Repository in lib/Zef.pm6
    method available(--> Array[Candidate]) {
        self!populate-distributions;

        my Candidate @candidates = @!distributions.map: -> $dist {
            Candidate.new(
                dist => $dist,
                uri  => ($dist.source-url || $dist.hash<support><source>),
                from => self.id,
                as   => $dist.identity,
            );
        }

        my Candidate @results = @candidates;
        return @results;
    }

    # Rebuild the manifest/index by recursively searching for META files
    method update {
        LEAVE { self.store(@!distributions) }
        self!update;
        self!populate-distributions;
    }

    # Method to allow self.store() call the equivilent of self.update() without infinite recursion
    method !update(-->Bool) {
        # $.cache/level1/level2/ # dirs containing dist files
        my @dirs    = $!cache.IO.dir.grep(*.d).map(*.dir.Slip).grep(*.d);
        my @dists   = grep { .defined }, map { try Zef::Distribution::Local.new($_) }, @dirs;
        my $content = join "\n", @dists.map: { join "\0", (.identity, .path) }
        so $content ?? self!spurt-package-list($content) !! False;
    }

    # see role Repository in lib/Zef.pm6
    method search(:$max-results, Bool :$strict, *@identities, *%fields --> Array[Candidate]) {
        return ().Seq unless @identities || %fields;

        my %specs = @identities.map: { $_ => Zef::Distribution::DependencySpecification.new($_) }
        my @searchable-identities = %specs.classify({ .value.from-matcher })<Perl6>.grep(*.defined).hash.keys;
        return ().Seq unless @searchable-identities;

        # populate %!short-name-lookup
        self!populate-distributions;

        my $grouped-results := @searchable-identities.map: -> $searchable-identity {
            my $wanted-spec         := %specs{$searchable-identity};
            my $wanted-short-name   := $wanted-spec.name;
            my $dists-to-search     := $strict ?? (%!short-name-lookup{$wanted-short-name} // Nil).grep(*.so) !! %!short-name-lookup{%!short-name-lookup.keys.grep(*.contains($wanted-short-name))}.map(*.Slip).grep(*.so);
            my $matching-candidates := $dists-to-search.grep(*.contains-spec($wanted-spec, :$strict)).map({
                Candidate.new(
                    dist => $_,
                    uri  => ($_.source-url || $_.hash<support><source>),
                    as   => $searchable-identity,
                    from => self.id,
                );
            });
            $matching-candidates;
        }

        # ((A_Match_1, A_Match_2), (B_Match_1)) -> ( A_Match_1, A_Match_2, B_Match_1)
        my Candidate @results = $grouped-results.map(*.Slip);

        return @results;
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

    # Location of db file
    has IO::Path $!package-list-path;
    method !package-list-path(--> IO::Path) {
        unless $!package-list-path {
            my $dir = $!cache.IO;
            $dir.mkdir unless $dir.e;
            $!package-list-path = $dir.child('MANIFEST.zef');
        }
        return $!package-list-path;
    }

    # Read our package db
    method !slurp-package-list(--> List) {
        return [ ] unless self!package-list-path.e;

        do given self!package-list-path.open(:r) {
            LEAVE {.close}
            .lock: :shared;
            .slurp.lines.map({.split("\0")[1]}).cache;
        }
    }

    # Write our package db
    method !spurt-package-list($content --> Bool) {
        do given self!package-list-path.open(:w) {
            LEAVE {.close}
            .lock;
            try .spurt($content);
        }
    }

    # Populate @!distributions and %!short-name-lookup, essentially initializing the data as late as possible
    has $!populate-distributions-lock = Lock.new;
    method !populate-distributions(--> Nil) {
        $!populate-distributions-lock.protect: {
            self!update if $.auto-update || !self!package-list-path.e;
            return if +@!distributions;

            for self!slurp-package-list -> $path {
                with try Zef::Distribution::Local.new($path) -> $dist {
                    # Keep track of out namespaces we are going to index later
                    my @short-names-to-index;

                    # Take the dist identity
                    push @short-names-to-index, $dist.name;

                    # Take the identity of each module in provides
                    # * The fast path doesn't work with provides entries that are long names (i.e. Foo:ver<1>)
                    # * The slow path results in parsing the module names in every distributions provides even though
                    #   long names don't work in rakudo (yet)
                    # * ...So maintain future correctness while getting the fast path in 99% of cases by doing a
                    #   cheap check for '<' and parsing only if needed
                    append @short-names-to-index, $dist.meta<provides>.keys.first(*.contains('<'))
                        ?? $dist.provides-specs.map(*.name) # slow path
                        !! $dist.meta<provides>.keys;       # fast path

                    # Index the short name to the distribution. Make sure entries are
                    # unique since dist name and one module name will usually match.
                    push %!short-name-lookup{$_}, $dist for @short-names-to-index.unique;

                    push @!distributions, $dist;
                }
            }
        }
    }
}
