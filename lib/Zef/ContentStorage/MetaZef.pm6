use Zef;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

# todo: clear search json files
class Zef::ContentStorage::MetaZef does ContentStorage {
    has $.mirrors;
    has $.fetcher is rw;
    has $.cache is rw;

    # only recent, not *all*
    method available {
        # currently 351 indexed on jdvs metacpan matching status:latest
        my $max-results = 100;
        $ = self.search(:$max-results, '*');
    }

    method IO {
        my $dir = $!cache.IO.child('metacpan');
        $dir.mkdir unless $dir.e;
        $dir;
    }

    # $max-results is max results *per* search, if max-results = 2 and there are
    # 2 identities then the max results returned could be 4
    method search(:$max-results = 5, :%params is copy, *@identities, *%fields) {
        return () unless @identities || %fields;

        %params<size> //= $max-results;
        my $params-string = %params.grep(*.value.defined).map(-> $p {
            $p.value.map({"{$p.key}=$_"}).join('&');
        }).join('&');

        # Unlike ::P6C and ::LocalCache we do not have access to a complete package index.
        # Instead we request meta data with a search term (the identity) and get results back.
        # TODO: compare results against DependencySpecificiation of $wants to make sure it/they
        # really match (currently trusts that the metacpan query result will contain the
        # requested identity) and filter out those that do not instead of assuming metacpan
        # will always do what we expect
        my $json;
        my $matches := gather DIST: for |@identities -> $wants {
            my $spec = Zef::Distribution::DependencySpecification.new($wants);

            temp %fields<distribution> = $spec.name #.subst('::', '-', :g)
                if ?$spec && $spec.name ne '*';
            temp %fields<version> = $spec.version-matcher.subst(/^v?/, '')
                if ?$spec && ?$spec.version-matcher && $spec.version-matcher ne '*';
            # not all dist have a `status` field with value `latest` yet, but we don't want
            # to exclude them from being searched for explicitly so only search for status:latest
            # if we have nothing to go on (like `zef list`)
            temp %fields<status> = 'latest'
                unless %fields<distribution>.?chars || %fields<version>.?chars;
            # auth/author are not usable on metacpan yet. `author` currently always lists
            # the maintainer of the metacpan fork, and auth is not always available (as x_auth).
            # Elsewhere we should just construct the auth from the other parts, but that doesn't help
            # us search if we don't already know what the part names are to begin with to searcn and
            # find the distribution in the first place
            # temp %fields<author>       = $wants-spec.auth-matcher.match(/^.*? ':' (.*)$/)[0].Str
            #    if ?$wants-spec.auth-matcher;
            my $qs = to-json(%fields);

            my $search-url = 'http://modules.zef.pm/api/module-search';

            # Query results currently saved to file for now to ease writing shell based
            # fetchers. Soon those will just print it to stdout, and return the captured raw data,
            # but the Fetcher interface needs to be updated to accommodate this.
            my $search-save-as = self.IO.child('search').IO.child("{time}.{$*THREAD.id}.json");
            my $response-path  = $!fetcher.fetch($search-url, $search-save-as, :query-string({
              query => $qs, 
            }));

            if $response-path.IO.e {
                my %meta = %(from-json($response-path.IO.slurp));
                try $response-path.unlink;

                for (^%meta<data>.elems) -> $i {
                    my $meta6;

                    my $dist      = Zef::Distribution.new(|%meta<data>[$i]);
                    my $candidate = Candidate.new(
                        dist  => $dist,
                        uri   => $dist.source-url,
                        as    => $wants,
                        from  => self.id,
                    );

                    take $candidate;
                }
            }
        }
    }
}
