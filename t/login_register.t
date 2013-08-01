#!/usr/bin/env perl6

BEGIN { @*INC.push('lib'); };

use Zef;
use JSON::Tiny;
use Test;
plan 6;

my $result = Zef.register( 'zef50000' , 'peterpan' , False );
ok( $result.status == 200 );
if $result.data.defined && $result.data<failure>.defined {
  ok( $result.data<reason> ~~ /'in use'/ , 'Checking for registration' );
} else {
  ok( $result.data<success>.defined , 'Checking for registration' );
}

$result = Zef.login( 'zef50000' , 'peterpan' , False );
ok( $result.status == 200 );
ok( $result.data.defined && $result.data<success>.defined , 'Testing successful login' );

$result = Zef.login( 'zef50000' , 'petergriffin' , False );
ok( $result.status == 200 );
ok( $result.data.defined && $result.data<failure>.defined , 'Testing failed login' );
