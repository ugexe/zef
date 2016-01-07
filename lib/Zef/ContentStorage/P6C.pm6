use Zef;
use Zef::Distribution;

class Zef::ContentStorage::P6C does ContentStorage {
    has $.mirrors;
    has $.auto-update;
    has $.fetcher is rw;
    has $.cache is rw;

    method IO { $ = $!cache.IO.child('p6c').IO }
    method package-list-file { $ = self.IO.child('packages.json').IO }
    method !slurp-package-list { @ = |from-json(self.package-list-file.slurp) }

    method update {
        die "Failed to update p6c" unless $!mirrors.first({ $!fetcher.fetch($_, self.package-list-file) });
    }

    method index { $ = $!cache.IO.child("p6c.json").IO }

    # todo: handle %fields
    method search(:$max-results = 5, *@identities, *%fields) {
        self.update if $.auto-update || !self.package-list-file.e;
        state @cache = self!slurp-package-list;
        return () unless @identities || %fields;
        my @search-us = @cache.grep({ $_<name> ~~ any(@identities.map(*.name)) }).map: { Zef::Distribution.new(|$_) }
        my @matches   = @identities.map(-> $ident { @search-us.first(-> $dist { $dist ~~ $ident }) }).grep(*.so);
    }
}