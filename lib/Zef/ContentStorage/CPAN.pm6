use Zef;

# todo: clear search json files
class Zef::ContentStorage::CPAN does ContentStorage {
    has $.mirrors;
    has $.fetcher is rw;
    has $.cache is rw;

    method IO { $ = $!cache.IO.child('metacpan').IO }

    method search(:$max-results = 5, *@identities, *%fields) {
        return () unless @identities || %fields;
        temp %fields<distribution> .= append(@identities);
        %fields<distribution> = %fields<distribution>>>.subst('::', '-', :g);

        my $query-string = %fields.map(-> $q { $q.value.map({"{$q.key}:$_"}).join('%20') }).join('%20');
        my $search-url = $!mirrors[0] ~ '_search?q=' ~ $query-string;
        my $search-save-as = self.IO.child('search').IO.child("{time}.{$*THREAD.id}.json");

        if ($ = $!fetcher.fetch($search-url, $search-save-as)).IO.e {
            if from-json($search-save-as.IO.slurp) -> $meta {
                $meta<hits><hits>.map: {
                    .<_source><metadata><source-url> = .<_source><download_url>.starts-with('/')
                        ?? "{$!mirrors[0]}{.<_source><download_url>.substr(1)}" 
                        !! .<_source><download_url>
                }
                # todo: $max-results via elastic search
                return $meta<hits><hits>.map({ .<_source><metadata> }).head($max-results);
            }
        }
    }
}

# Just in case the META6.json doesn't provide everything we end up needing
# this can be used to try and build it from data metacpan builds itself
sub METACPAN2META6(%cpan-meta) {
    my %meta;
    %meta<name>        = %cpan-meta<distribution>.subst('-', '::');
    %meta<version>     = %cpan-meta<version_numified>;
    %meta<author>      = %cpan-meta<author>;
    %meta<description> = %cpan-meta<abstract>;
    %meta<depends>     = %cpan-meta<dependency>.map({ .<module> ~ (.<version_numified> ?? ":{.<version_numified>}" !! '') }).join(',');
    %meta<provides>    = %cpan-meta<provides>.map({ $_ => "lib/{$_.subst('::', '/')}.pm6" }); # ???
    %meta<license>     = %cpan-meta<license>.join(',');

    %meta<authority>   = 'cpan';
    %meta<auth>        = %meta<authority> ~ ':' ~ %meta<author>;
    # not official spec; imitate p6c/ecosystem for now
    %meta<source-url> = %cpan-meta<download_url>;
}