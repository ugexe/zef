use v6;
use Test;
plan 1;

use Zef::Distribution::Local;
use Zef;

subtest {
    subtest {
			  my $path = 't/test-meta-files/xyz.json';
		    my $dist = Zef::Distribution::Local.new($path);
        my @deps = $dist.depends-specs;
        dd @deps;
    }, 'github:ugexe:Net--HTTP:1.0';
}, 'Distribution URN';
