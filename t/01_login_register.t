#!/usr/bin/env perl6

BEGIN { @*INC.push('lib'); };

use Zef;
use JSON::Tiny;
use Test;
plan 6;


my $result = Zef.register( username => 'zef50000', password => 'peterpan', autoupdate => False );
ok( $result.status == 200 );

($result.data.defined && $result.data<failure>.defined)
	?? ok( $result.data<reason> ~~ /'in use'/ , 'Checking for registration' )
  	!! ok( $result.data<success>.defined , 'Checking for registration' );

sleep 3;
$result = Zef.login( username => 'zef50000', password => 'peterpan', autoupdate => False );
ok( $result.status == 200 );
ok( $result.data.defined && $result.data<success>.defined , 'Testing successful login' );

sleep 3;
$result = Zef.login( username => 'zef50000', password => 'petergriffin', autoupdate => False );
ok( $result.status == 200 );
ok( $result.data.defined && $result.data<failure>.defined , 'Testing failed login' );



