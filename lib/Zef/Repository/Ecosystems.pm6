use Zef;
use Zef::Utils::FileSystem;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

class Zef::Repository::Ecosystems does Repository {
    has $.name;
    has $.mirrors;
    has $.auto-update is rw;

    has $.fetcher;
    has $.cache;
    has $.update-counter;
    has @!dists;

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

        # XXX: Delete this eventually
        my $dispatchers := $*PERL.compiler.version < v2018.08
            ?? self!gather-dists
            !! self!gather-dists.race;

        my @matches = $dispatchers.map: -> $dist {
            @searchable-identities.grep({ $dist.contains-spec(%specs{$_}, :$strict) }).map({
                Candidate.new(
                    dist => $dist,
                    uri  => ($dist.source-url || $dist.hash<support><source>),
                    as   => $_,
                    from => self.id,
                );
            }).Slip
        }

        return @matches;
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
            take($_) with try Zef::Distribution.new(|%($meta));
        }
    }
}
