use Zef;
use Zef::Distribution::Local;

class Zef::ContentStorage::LocalCache does ContentStorage {
    has $.mirrors;
    has $.auto-update;
    has $.cache is rw;

    has @!dists;

    method !gather-dists {
        once { self.update } if $.auto-update || !self!manifest-file.e;
        @!dists = +@!dists ?? @!dists !! self!manifest-file.lines.map: -> $entry {
            my ($identity, $path) = $entry.split("\0");
            $ = Zef::Distribution::Local.new($path);
        }
        @!dists;
    }

    method !manifest-file  { $ = self.IO.child('MANIFEST.zef') }

    method IO {
        my $dir = $!cache.IO;
        $dir.mkdir unless $dir.e;
        $dir;
    }

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

            if Zef::Distribution::Local.new($current) -> $dist {
                %dcache{$dist.id} //= $dist;
            }
        }

        my $data = %dcache.map({ (.key, .value.IO.absolute).join("\0") }).join("\n");
        self!manifest-file.spurt($data);
        @!dists = %dcache.values;
    }

    # todo: handle %fields
    method search(:$max-results = 5, *@identities, *%fields) {
        my $matches := gather DIST: for self!gather-dists -> $dist {
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

    method store(*@dists) {
        my $lines = self!manifest-file.lines;
        my $data  = @dists\
            .grep({ !$lines.first(*.starts-with($_.id)) })\
            .map({ (.id, .IO.absolute).join("\0") })\
            .join("\n");
        self!manifest-file.spurt(:append, "{$data}\n") if $data;
    }
}
