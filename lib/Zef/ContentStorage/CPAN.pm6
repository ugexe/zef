use Zef;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

# todo: clear search json files
class Zef::ContentStorage::CPAN does ContentStorage {
    has $.mirrors;
    has $.fetcher is rw;
    has $.cache is rw;

    method IO {
        my $dir = $!cache.IO.child('metacpan');
        $dir.mkdir unless $dir.e;
        $dir;
    }

    # $max-results is max results *per* search, if max-results = 2 and there are
    # 2 identities then the max results returned could be 4
    method search(:$max-results = 5, *@identities, *%fields) {
        return () unless @identities || %fields;

        # Unlike ::P6C and ::LocalCache we do not have access to a complete package index.
        # Instead we request meta data with a search term (the identity) and get results back.
        # TODO: compare results against DependencySpecificiation of $wants to make sure it/they
        # really match (currently trusts that the metacpan query result will contain the
        # requested identity) and filter out those that do not instead of assuming metacpan
        # will always do what we expect
        my $matches := gather DIST: for |@identities -> $wants {
            my $wants-spec = Zef::Distribution::DependencySpecification.new($wants);
            temp %fields<distribution> = $wants-spec.name.subst('::', '-', :g);
            temp %fields<version>      = $wants-spec.version-matcher.subst(/^v?/, '?')
                if ?$wants-spec.version-matcher && $wants-spec.version-matcher ne '*';

            # auth/author are not usable on metacpan yet. `author` currently always lists
            # the maintainer of the metacpan fork, and auth is not always available (as x_auth).
            # Elsewhere we should just construct the auth from the other parts, but that doesn't help
            # us search if we don't already know what the part names are to begin with to searcn and
            # find the distribution in the first place
            # temp %fields<author>       = $wants-spec.auth-matcher.match(/^.*? ':' (.*)$/)[0].Str
            #    if ?$wants-spec.auth-matcher;

            my $query-string = %fields.grep(*.value.defined).map(-> $q {
                $q.value.map({"{$q.key}:$_"}).join('%20')
            }).join('%20AND%20');
            my $search-url = $!mirrors[0] ~ '_search?q=' ~ $query-string;

            # Query results currently saved to file for now to ease writing shell based
            # fetchers. Soon those will just print it to stdout, and return the captured raw data,
            # but the Fetcher interface needs to be updated to accommodate this.
            my $search-save-as = self.IO.child('search').IO.child("{time}.{$*THREAD.id}.json");
            my $response-path = $!fetcher.fetch($search-url, $search-save-as);

            if $!fetcher.fetch($search-url, $search-save-as) -> $reponse-path {
                if from-json($response-path.IO.slurp) -> %meta {
                    # This should generally return the same distribution but in various versions.
                    # However we will need to be prepared for when multiple distributions are returned
                    # and sorting by version may no longer make sense
                    my @candidates = (^%meta<hits><hits>.elems).map: {
                        my $meta6 = METACPAN2META6(%meta<hits><hits>[$_]<_source>);
                        # temporary. Some download_urls are absolute, and others are not
                        my $host           = 'http://hack.p6c.org:5001';
                        $meta6<source-url> = ($host ~ $meta6<source-url>) if $meta6<source-url>.starts-with('/');

                        my $dist      = Zef::Distribution.new(|$meta6);
                        my $candidate = Candidate.new(
                            dist           => $dist,
                            uri            => $dist.source-url,
                            requested-as   => $wants,
                            recommended-by => self.^name,
                        );
                    }

                    my $sorted = |@candidates.sort({ $^b.dist cmp $^a.dist }).head($max-results [min] @candidates.elems);

                    take $sorted;
                }
            }
        }
    }
}

# This is just a hack to try and create a meta6 from what metacpan gives us. This is often
# missing items (but not always) like provides which will likely always be present in a
# perl6 specific API search result
sub METACPAN2META6(%cpan-meta) {
    my $meta6;
    $meta6<name>        = (%cpan-meta<distribution> // %cpan-meta<metadata><name> // '').subst('-', '::', :g);
    $meta6<version>     = (%cpan-meta<metadata><version> // %cpan-meta<version_numified> // '*');
    $meta6<author>      = (%cpan-meta<metadata><author> // '');
    $meta6<description> = (%cpan-meta<abstract> // %cpan-meta<metadata><description> // '');
    $meta6<license>     = (%cpan-meta<license> // '').join(',');
    $meta6<provides>    = (%cpan-meta<metadata><provides>.kv.map: { $^a => $^b<file> } // {});

    $meta6<depends>     = %cpan-meta<metadata><x_depends>;

    $meta6<auth>        = %cpan-meta<metadata><x_auth> // %cpan-meta<metadata><x_authority> // $meta6<author> // '';
    $meta6<auth> = '' if $meta6<auth> eq 'unknown';

    # not official spec, but it *is* a Distribution attribute
    $meta6<source-url>  = %cpan-meta<download_url>;

    $meta6;
}