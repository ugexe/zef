use v6;
use Test;
plan 6;

use Zef::Identity;


subtest 'Require spec - exact' => {
    my @variations = (
        'Net::HTTP:ver<1.0>:auth<Foo Bar \<f.bar@email.com\>>',
        'Net::HTTP:auth<Foo Bar \<f.bar@email.com\>>:ver<1.0>:api<>',
    );

    for @variations -> $identity {
        my $ident = Zef::Identity.new($identity);

        is $ident.auth,    'Foo Bar <f.bar@email.com>';
        is $ident.name,    'Net::HTTP';
        is $ident.version, '1.0';
    }
}


subtest 'Require spec - range *' => {
    my @variations = (
        "Net::HTTP:ver<*>:auth<github:ugexe>",
    );

    for @variations -> $identity {
        my $ident = Zef::Identity.new($identity);

        is $ident.auth,    'github:ugexe';
        is $ident.name,    'Net::HTTP';
        is $ident.version, '*';
    }
}


subtest 'Require spec - range +' => {
    my @variations = (
        "Net::HTTP:ver<1.0+>:auth<github:ugexe>",
        "Net::HTTP:auth<github:ugexe>:ver<1.0+>:api<>",
    );

    for @variations -> $identity {
        my $ident = Zef::Identity.new($identity);

        is $ident.auth,    'github:ugexe';
        is $ident.name,    'Net::HTTP';
        is $ident.version, '1.0+';
    }
}


subtest 'str2identity' => {
    ok ?str2identity("***not valid***");

    subtest 'exact' => {
        my $expected  = "Net::HTTP:ver<1.0+>:auth<github:ugexe>";
        my $require   = "Net::HTTP:ver<1.0+>:auth<github:ugexe>:api<>";
        my $i-require = str2identity($require);

        is $i-require, $expected;
    }

    subtest 'not exact' => {
        my $require = "Net::HTTP";
        my $i-require = str2identity($require);

        is $i-require, 'Net::HTTP';
    }

    subtest 'root namespace' => {
        my $require = "HTTP";
        my $i-require = str2identity($require);

        is $i-require, 'HTTP';
    }
}


subtest 'identity2hash' => {
    my $require = "Net::HTTP:ver<1.0+>:auth<github:ugexe>";
    ok ?identity2hash("***not valid***");

    my %i-require = identity2hash($require);

    is %i-require<name>, 'Net::HTTP';
    is %i-require<ver>,  '1.0+';
    is %i-require<auth>, 'github:ugexe';
}


subtest 'hash2identity' => {
    my %hash    = %( :name<Net::HTTP>, :ver<1.0+>, :auth<github:ugexe> );
    ok ?hash2identity("***not valid***");

    my $i-require = hash2identity(%hash);

    is $i-require, "Net::HTTP:ver<1.0+>:auth<github:ugexe>";
}
