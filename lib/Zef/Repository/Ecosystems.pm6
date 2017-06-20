use Zef;
use Zef::Utils::FileSystem;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

class Zef::Repository::Ecosystems does Repository {
    has $.name;
    has $.mirrors;
    has $.auto-update;

    has $.fetcher is rw;
    has $.cache   is rw;
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

    method update(--> Bool) {
        $!update-counter++;

        so $!mirrors.first: -> $uri {
            # TODO: use the logger to send these as events
            UNDO note "!!!> Failed to update $!name mirror: $uri";
            KEEP note "===> Updated $!name mirror: $uri";
            KEEP self!gather-dists;

            my $save-as  = $!cache.IO.child($uri.IO.basename);
            my $saved-as = try $!fetcher.fetch($uri, $save-as);
            next unless $saved-as.e;

            # this is kinda odd, but if $path is a file, then its fetching via http from p6c.org
            # and if its a directory its pulling from my ecosystems repo (this hides the difference for now)
            $saved-as .= child("{$!name}.json") if $saved-as.d;
            next unless $saved-as.e;

            lock-file-protect("{$saved-as}.lock", -> {
                self!spurt-package-list($saved-as.slurp(:bin))
            });
        }
    }

    # todo: handle %fields
    # todo: search for up to $max-results number of candidates for each *dist* (currently only 1 candidate per identity)
    method search(:$max-results = 5, Bool :$strict, *@identities, *%fields --> Seq) {
        return () unless @identities || %fields;
        my @wanted = @identities;
        my %specs  = @wanted.map: { $_ => Zef::Distribution::DependencySpecification.new($_) }

        gather for |self!gather-dists -> $dist {
            for @identities.grep({ $dist.contains-spec(%specs{$_}, :$strict) }) -> $wanted-as {
                take Candidate.new(
                    dist => $dist,
                    uri  => ($dist.source-url || $dist.hash<support><source>),
                    as   => $wanted-as,
                    from => self.id,
                );
            }
        }
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

    # Abstraction to handle automatic updating of package list and/or local index
    method !gather-dists(--> List) {
        # Only update once, and only update automatically if $!auto-update is enabled or no package list exists yet
        self.update if !$!update-counter && ($!auto-update || !self!package-list-path.e);
        return @!dists if +@!dists;

        @!dists = eager gather for self!slurp-package-list -> $meta {
            take($_) with try Zef::Distribution.new(|%($meta));
        }
    }
}