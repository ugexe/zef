#!/usr/bin/env perl6

BEGIN { @*INC.push('lib'); };

use Zef;
use JSON::Tiny;
use Test;
plan 4;

my $result = Zef.search( module => 'CSV' );
ok( $result.status.defined && $result.status == 200 , "Status code check.");
ok( $result.headers.defined && 
    $result.headers<Content-Type>.defined && 
    $result.headers<Content-Type> eq 'application/json', 'Content-Type check');
ok( $result.data.defined && 
    ( $result.data ~~ Hash || 
      $result.data ~~ Array ) , "Converting response data to json" );

say 'Sleeping for 3 seconds because the p6 server is so slow';
sleep 3;
my $no_result = Zef.search( module => 'RMS_Favorite_web_browser' );
ok( !$result.status.defined, 'Searching for non-existant (we hope!) module');
