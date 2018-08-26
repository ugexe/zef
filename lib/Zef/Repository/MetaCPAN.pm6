use Zef;
use Zef::Distribution;
use Zef::Distribution::DependencySpecification;

# todo: clear search json files
class Zef::Repository::MetaCPAN does Repository {
    has $.mirrors;
    has $.fetcher;
    has $.cache;

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

        # TODO: modify query to allow for exact or fuzzy namespace matching before deleting
        %fields<strict>:delete if %fields<strict>:exists;

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

        my $matches := gather for @identities -> $wants {
            my $spec = Zef::Distribution::DependencySpecification.new($wants);

            next unless ($spec.from-matcher // '') eq 'Perl6';

            temp %fields<distribution> = $spec.name.subst('::', '-', :g)
                if ?$spec && $spec.name ne '*';
            temp %fields<version> = $spec.version-matcher.subst(/^v?/, '?')
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

            my $query-string = %fields.grep(*.value.defined).map(-> $q {
                $q.value.map({"{$q.key}:$_"}).join('%20')
            }).join('%20AND%20') // '';

            my $search-url = "{$!mirrors[0]}_search?"
                ~ ($params-string ?? "$params-string&" !! '')
                ~ ($query-string  ?? "q=$query-string" !! '');

            # Query results currently saved to file for now to ease writing shell based
            # fetchers. Soon those will just print it to stdout, and return the captured raw data,
            # but the Fetcher interface needs to be updated to accommodate this.
            my $search-save-as = self.IO.child('search').IO.child("{time}.{$*THREAD.id}.json")
                andthen {.parent.mkdir unless .parent.e};

            my $response-path  = $!fetcher.fetch($search-url, ~$search-save-as, :timeout(180));
            next() R, note "!!!> MetaCPAN query failed to fetch [$search-url]"
                unless $response-path && $response-path.IO.e;
            note "===> MetaCPAN query responded [$search-url]";

            if $response-path && $response-path.IO.e {
                my %meta = %(from-json($response-path.IO.slurp));
                try $response-path.unlink;

                for (^%meta<hits><hits>.elems) -> $i {
                    my $meta6 = METACPAN2META6(%meta<hits><hits>[$i]<_source>);
                    # temporary. Some download_urls are absolute, and others are not
                    my $host           = 'http://hack.p6c.org:5001';
                    $meta6<source-url> = ($host ~ $meta6<source-url>) if $meta6<source-url>.starts-with('/');

                    my $dist      = Zef::Distribution.new(|$meta6);
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

    $meta6<depends>       = %cpan-meta<metadata><x_depends>;
    $meta6<build-depends> = %cpan-meta<metadata><x_build-depends>;
    $meta6<test-depends>  = %cpan-meta<metadata><x_test-depends>;

    $meta6<auth>        = %cpan-meta<metadata><x_auth> // %cpan-meta<metadata><x_authority> // $meta6<author> // '';
    $meta6<auth> = '' if $meta6<auth> eq 'unknown';

    # not official spec, but it *is* a Distribution attribute
    $meta6<source-url>  = %cpan-meta<download_url>;

    $meta6;
}
