use v6;
use Test;
plan 6;

use Zef::Identity;


subtest {
    my @variations = (
        "Net::HTTP:ver<1.0>:auth<github:ugexe>",
        "Net::HTTP:auth<github:ugexe>:ver<v1.0>:api<>",
    );

    for @variations -> $identity {
        my $ident = Zef::Identity.new("Net::HTTP:ver<1.0>:auth<github:ugexe>");

        is $ident.auth,    'github:ugexe';
        is $ident.name,    'Net::HTTP';
        is $ident.version, '1.0';
    }
}, 'Require spec - exact';


subtest {
    my @variations = (
        "Net::HTTP:ver<*>:auth<github:ugexe>",
    );

    for @variations -> $identity {
        my $ident = Zef::Identity.new("Net::HTTP:ver<*>:auth<github:ugexe>");

        is $ident.auth,    'github:ugexe';
        is $ident.name,    'Net::HTTP';
        is $ident.version, '*';
    }
}, 'Require spec - range *';


subtest {
    my @variations = (
        "Net::HTTP:ver<1.0+>:auth<github:ugexe>",
        "Net::HTTP:auth<github:ugexe>:ver<1.0+>:api<>",
    );

    for @variations -> $identity {
        my $ident = Zef::Identity.new("Net::HTTP:ver<1.0+>:auth<github:ugexe>");

        is $ident.auth,    'github:ugexe';
        is $ident.name,    'Net::HTTP';
        is $ident.version, '1.0+';
    }
}, 'Require spec - range +';


subtest {
    ok ?str2identity("***not valid***");

    subtest {
        my $expected  = "Net::HTTP:ver<1.0+>:auth<github:ugexe>";
        my $require   = "Net::HTTP:ver<1.0+>:auth<github:ugexe>:api<>";
        my $i-require = str2identity($require);

        is $i-require, $expected;
    }, 'exact';

    subtest {
        my $require = "Net::HTTP";
        my $i-require = str2identity($require);

        is $i-require, 'Net::HTTP';
    }, 'not exact';

    subtest {
        my $require = "HTTP";
        my $i-require = str2identity($require);

        is $i-require, 'HTTP';
    }, 'root namespace';
}, 'str2identity';


subtest {
    my $require = "Net::HTTP:ver<1.0+>:auth<github:ugexe>";
    my %hash    = %( :name<Net::HTTP>, :ver<1.0+>, :auth<github:ugexe> );
    ok ?identity2hash("***not valid***");

    my %i-require = identity2hash($require);

    is %i-require<name>, 'Net::HTTP';
    is %i-require<ver>,  '1.0+';
    is %i-require<auth>, 'github:ugexe';
}, 'identity2hash';


subtest {
    my $require = "Net::HTTP:ver<1.0+>:auth<github:ugexe>";
    my %hash    = %( :name<Net::HTTP>, :ver<1.0+>, :auth<github:ugexe> );
    ok ?hash2identity("***not valid***");

    my $i-require = hash2identity(%hash);

    is $i-require, "Net::HTTP:ver<1.0+>:auth<github:ugexe>";
}, 'hash2identity';
