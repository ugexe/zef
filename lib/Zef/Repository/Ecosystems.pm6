use Zef;
use Zef::Utils::FileSystem;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

class Zef::Repository::Ecosystems does Repository {
    has $.name;
    has $.mirrors;
    has $.auto-update is rw;
    has $.uses-path is rw;

    has $.fetcher;
    has $.cache;
    has $.update-counter;
    has @!dists;
    has %!short-name-lookup;

    method id(--> Str) { $?CLASS.^name.split('+', 2)[0] ~ "<{$!name}>" }

    method IO(--> IO::Path) { my $dir = $!cache.IO.child($!name); $dir.mkdir unless $dir.e; $dir }

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

    method update {
        $!update-counter++;

        $!mirrors.first: -> $uri {
            # TODO: use the logger to send these as events
            note "===> Updating $!name mirror: $uri";
            UNDO note "!!!> Failed to update $!name mirror: $uri";
            KEEP note "===> Updated $!name mirror: $uri";
            KEEP self!gather-dists;

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

        self!gather-dists;
    }

    # todo: handle %fields
    # todo: search for up to $max-results number of candidates for each *dist* (currently only 1 candidate per identity)
    method search(:$max-results = 5, Bool :$strict, *@identities, *%fields) {
        return ().Seq unless @identities || %fields;

        my %specs = @identities.map: { $_ => Zef::Distribution::DependencySpecification.new($_) }
        my @searchable-identities = %specs.classify({ .value.from-matcher })<Perl6>.grep(*.defined).hash.keys;
        return ().Seq unless @searchable-identities;

        # populate %!short-name-lookup
        $ = self!gather-dists;

        my $grouped-results := @searchable-identities.map: -> $searchable-identity {
            my $wanted-spec         := %specs{$searchable-identity};
            my $wanted-short-name   := $wanted-spec.name;
            my $dists-to-search     := $strict ?? %!short-name-lookup{$wanted-short-name}.grep(*.so) !! %!short-name-lookup{%!short-name-lookup.keys.grep(*.contains($wanted-short-name))}.map(*.Slip).grep(*.so);
            my $matching-candidates := $dists-to-search.grep(*.contains-spec($wanted-spec, :$strict)).map({
                my $uri;
                if $_.meta<path> && $.uses-path {
                    $uri = $_.meta<path>;
                    $uri ~~ s/^repo\///;
                    $uri = $.mirrors.first ~ $uri;
                }
                Candidate.new(
                    dist => $_,
                    uri  => ($uri || $_.source-url || $_.hash<support><source>),
                    as   => $searchable-identity,
                    from => self.id,
                );
            });
            $matching-candidates;
        }

        # ((A_Match_1, A_Match_2), (B_Match_1)) -> ( A_Match_1, A_Match_2, B_Match_1)
        my $results := $grouped-results.map(*.Slip);

        return @$results;
    }

    method !package-list-path(--> IO::Path) { self.IO.child($!name ~ '.json') }

    method !slurp-package-list(--> List) {
        return [ ] unless self!package-list-path.e;

        do given self!package-list-path.open(:r) {
            LEAVE {.close}
            .lock: :shared;
            try |from-json(.slurp);
        }
    }

    method !spurt-package-list($content --> Bool) {
        do given self!package-list-path.open(:w) {
            LEAVE {.close}
            .lock;
            try .spurt($content);
        }
    }

    method !is-package-list-stale {
        return !self!package-list-path.e
            || ($!auto-update && self!package-list-path.modified < now.DateTime.earlier(:hours($!auto-update)).Instant);
    }

    # Abstraction to handle automatic updating of package list and/or local index
    method !gather-dists(--> List) {
        self.update if !$!update-counter && self!is-package-list-stale;
        return @!dists if +@!dists;

        @!dists = eager gather for self!slurp-package-list -> $meta {
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

                take($dist);
            }
        }
    }
}
