#!/usr/bin/env perl6

BEGIN { @*INC.push('lib'); };

use Zef;
use JSON::Tiny;
use Test;
plan 3;

my $result = Zef.search( 'CSV' );
ok( $result.status == 200 , "Status code check.");
ok( $result.headers<Content-Type> eq 'application/json', 'Content-Type check');
ok( from-json( $result.data ) , "Converting response data to json" );
