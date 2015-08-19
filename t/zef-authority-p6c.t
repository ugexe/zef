use v6;
use Zef::Authority::P6C;
use Test;
plan 1;


subtest {
    ok my $authority = Zef::Authority::P6C.new;
    #my @results    = $authority.search('zef');
    #my @no-results = $authority.search("#");

    #ok @results.elems, "Got modules (search: zef)";
    #is @no-results.elems, 0, "Got 0 modules (search: #)";
}, 'P6C';
