use Zef;

class Zef::Service::DistributionBuilder does Builder does Messenger {
    method build-matcher($dist) { ($dist.meta-version // 0) == 1 }
    method needs-build($dist) { self.build-matcher($dist) and $dist.builder }

    method probe { True }

    method build($dist, :@includes) {
        my $meta := $dist.meta;
        return (require ::("Distribution::Builder::$dist.builder()")).new(:$meta).build($dist.path);
    }
}
