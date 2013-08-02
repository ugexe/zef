#!/usr/bin/env perl6

BEGIN { @*INC.push('lib'); };

use Zef;
use JSON::Tiny;
use Test;
plan 3;

my $result = Zef.search( 'CSV' );
ok( $result.status.defined && $result.status == 200 , "Status code check.");
ok( $result.headers.defined && 
    $result.headers<Content-Type>.defined && 
    $result.headers<Content-Type> eq 'application/json', 'Content-Type check');
ok( $result.data.defined && 
    ( $result.data ~~ Hash || 
      $result.data ~~ Array ) , "Converting response data to json" );
