use Zef;

class Zef::Service::Shell::Build does Builder does Messenger {
    method build-matcher($dist) { ($dist.meta-version // 0) == 1 }

    method probe { True }

    method build($dist, :@includes) {
        die "path does not exist: {$dist.path}" unless $dist.path.IO.e;

        if $dist.builder {
            my $meta-text = $dist.path.IO.child('META6.json').slurp;
            my $meta = Rakudo::Internals::JSON.from-json($meta-text);
            temp $*CWD = $dist.path.IO;
            return (require ::("Distribution::Builder::$dist.builder()")).new(:$meta).build;
        }

        return True;
    }
}
