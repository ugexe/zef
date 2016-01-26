use Zef;
use Zef::Distribution::Local;

# Intended to:
# 1) Keep track of contents of a directory using a manifest.
#   a) full update to recursively search location to discover everything
#   b) .store method to be called after something is fetched, allowing
#       the single entry to be added to the manifest without having to search
# 2) If a requested identity matches anything found in the manifest already
#    then it will return *that* instead of necessarily making net requests
#    for other ContentStorage like p6c or CPAN (although such choices are
#    made inside Zef::ContentStorage itself)
class Zef::ContentStorage::LocalCache does ContentStorage {
    state $lock = Lock.new;
    has $.mirrors;
    has $.auto-update;
    has $.cache is rw;

    has @!dists;

    # Abstraction to handle automatic updating of package list and/or local index
    method !gather-dists {
        once { self.update } if $.auto-update || !self!manifest-file.e;
        return @!dists if +@!dists;

        @!dists = gather for self!manifest-file.lines -> $entry {
            my ($identity, $path) = $entry.split("\0");
            next unless $path.IO.e;
            try {
                my $dist = Zef::Distribution::Local.new($path);
                take $dist;
            }
        }
    }

    method !manifest-file  { $ = self.IO.child('MANIFEST.zef') }

    method IO {
        my $dir = $!cache.IO;
        $dir.mkdir unless $dir.e;
        $dir;
    }

    # Rebuild the manifest/index by recursively searching for META files
    method update {
        my @stack = $!cache;
        my %dcache;

        while ( @stack ) {
            my $current = @stack.pop.IO;
            next if !$current.e
                ||  $current.f
                ||  $current.basename.starts-with('.')
                ||  %dcache.values.grep({ $current.absolute.starts-with($_.IO.absolute) });

            unless ?Zef::Distribution::Local.find-meta($current) {
                @stack.append($current.dir.grep(*.d)>>.absolute);
                next;
            }

            try {
                if Zef::Distribution::Local.new($current) -> $dist {
                    %dcache{$dist.id} //= $dist;
                }
            }
        }

        @!dists = %dcache.values;
        self!update;
    }

    method !update(*@dists) {
        self.store(|@!dists);
        @!dists;
    }

    # todo: handle %fields
    # todo: sort $max-results results by version
    method search(:$max-results = 5, *@identities, *%fields) {
        my $matches := gather DIST: for |self!gather-dists -> $dist {
            state @wanted = |@identities;
            for @identities.grep(* ~~ any(@wanted)) -> $wants {
                my $spec = Zef::Distribution::DependencySpecification.new($wants);
                if ?$dist.contains-spec($spec) {
                    take $dist;
                    @wanted.splice(@wanted.first(/$wants/, :k), 1);
                    last DIST unless +@wanted;
                }
            }
        }
    }

    # After the `fetch` phase an app can call `.store` on any ContentStorage that
    # provides it, allowing each ContentStorage to do things like keep a simple list of
    # identities installed, keep a cache of anything installed (how its used here), etc
    method store(*@dists) {
        $lock.protect({
            my $handle = self!manifest-file.open(:rw);
            LEAVE { try {$handle.close} if $handle && $handle.opened }

            my %lookup;

            for $handle.lines {
                my ($id, $path) = .split("\0");
                %lookup{$id} = $path if $path && $path.IO.d;
            }

            @dists.map: { %lookup{.id} = .IO.absolute }

            my $manifest-contents = join "\n", %lookup.map: { join "\0", (.key, .value) }
            try { $handle.say($manifest-contents) } if $manifest-contents;
        })
    }
}
