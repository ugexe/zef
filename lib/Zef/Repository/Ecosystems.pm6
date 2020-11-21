use Zef;
use Zef::Utils::FileSystem;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

# A basic 'Repository' that uses a file (containing an array of hash / META6 json) as a database. It is
# used for the default 'p6c' and 'cpan' ecosystems, and is also a good choice for ad-hoc darkpans by passing
# it your own mirrors in the config.

class Zef::Repository::Ecosystems does Repository {
    # A name for the repository/ecosystem to be referenced (i.e. '===> Updated myname mirror: ...')
    has Str $.name;

    # One or more URIs containing an ecosystem 'array-of-hash' database. URI types that work
    # are whatever the supplied $!fetcher supports (so generally local files and https)
    has List $.mirrors;

    # Int | Bool
    # Int - the db will be lazily updated when it is $!auto-update hours old
    # Bool True - the db will be lazily updated regardless of how old the db is
    # Bool False - do not update the db
    has $.auto-update is rw;

    # Where we will save/stage the db file we fetch
    has IO::Path $.cache;

    # Used to get data from a URI. Generally uses Zef::Fetcher, which itself uses multiple backends to allow
    # fetching local paths, https, and git by default
    has Fetcher $.fetcher;

    # A array of distributions found in the ecosystem db. Lazily populated as soon as the db is referenced
    has Zef::Distribution @!distributions;

    # Similar to @!distributions, but indexes by short name i.e. { "Foo::Bar" => ($dist1, $dist2), "Baz" => ($dist1) }
    has Array[Distribution] %!short-name-lookup;

    # see role Repository in lib/Zef.pm6
    method id(--> Str) { $?CLASS.^name.split('+', 2)[0] ~ "<{$!name}>" }

    # see role Repository in lib/Zef.pm6
    method available(--> Array[Candidate]) {
        self!populate-distributions;

        my @candidates = @!distributions.map: -> $dist {
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

    # Iterate over mirrors until we successfully fetch and save one
    # see role Repository in lib/Zef.pm6
    has Int $!update-counter; # Keep track if we already did an update during this runtime
    method update(--> Nil) {
        $!update-counter++;

        $!mirrors.first: -> $uri {
            # TODO: use the logger to send these as events
            note "===> Updating $!name mirror: $uri";
            UNDO note "!!!> Failed to update $!name mirror: $uri";
            KEEP note "===> Updated $!name mirror: $uri";

            my $save-as  = $!cache.IO.child($uri.IO.basename);
            my $saved-as = try {
                CATCH { default { .note; } }
                $!fetcher.fetch(Candidate.new(:$uri), $save-as, :timeout(180));
            }
            next unless $saved-as.?chars && $saved-as.IO.e;

            # this is kinda odd, but if $path is a file, then its fetching via http from p6c.org
            # and if its a directory its pulling from my ecosystems repo (this hides the difference for now)
            $saved-as .= child("{$!name}.json") if $saved-as.d;
            next unless $saved-as.e;

            lock-file-protect("{$saved-as}.lock", -> {
                self!spurt-package-list($saved-as.slurp(:bin))
            });
        }
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

    # Location of db file
    has IO::Path $!package-list-path;
    method !package-list-path(--> IO::Path) {
        unless $!package-list-path {
            my $dir = $!cache.IO.child($!name);
            $dir.mkdir unless $dir.e;
            $!package-list-path = $dir.child($!name ~ '.json');
        }
        return $!package-list-path;
    }

    # Read our package db
    method !slurp-package-list(--> List) {
        return [ ] unless self!package-list-path.e;

        do given self!package-list-path.open(:r) {
            LEAVE {.close}
            .lock: :shared;
            try |from-json(.slurp);
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

    # Check if our package list should be updated
    method !is-package-list-stale(--> Bool:D) {
        return !self!package-list-path.e
            || ($!auto-update && self!package-list-path.modified < now.DateTime.earlier(:hours($!auto-update)).Instant);
    }

    # Populate @!distributions and %!short-name-lookup, essentially initializing the data as late as possible
    has $!populate-distributions-lock = Lock.new;
    method !populate-distributions(--> Nil) {
        $!populate-distributions-lock.protect: {
            self.update if !$!update-counter && self!is-package-list-stale;
            return if +@!distributions;

            for self!slurp-package-list -> $meta {
                with try Zef::Distribution.new(|%($meta)) -> $dist {
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
