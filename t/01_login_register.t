#!/usr/bin/env perl6

BEGIN { @*INC.push('lib'); };

use Zef;
use JSON::Tiny;
use Test;
plan 6;


my $result = Zef.register( 'zef50000' , 'peterpan' , False );
ok( $result.status == 200 );

($result.data.defined && $result.data<failure>.defined)
	?? ok( $result.data<reason> ~~ /'in use'/ , 'Checking for registration' )
  	!! ok( $result.data<success>.defined , 'Checking for registration' );

sleep 3;
$result = Zef.login( 'zef50000' , 'peterpan' , False );
ok( $result.status == 200 );
ok( $result.data.defined && $result.data<success>.defined , 'Testing successful login' );

sleep 3;
$result = Zef.login( 'zef50000' , 'petergriffin' , False );
ok( $result.status == 200 );
ok( $result.data.defined && $result.data<failure>.defined , 'Testing failed login' );


=begin comment
UTF8 tests so somebody can use the poop emoticon for their username
+6 test count, uncomment, remove if $result {}, and s/skip/ok/ when utf8 stuff doesnt hang
Have to comment out instead of just skipping as Zef.register/login crash with utf8
{
	sleep 3;
	my $result = Zef.register( 'ⓕⓞⓞ' , 'unicode' , False );
	skip( $result.status == 200 );

	($result.data.defined && $result.data<failure>.defined)
		?? skip( $result.data<reason> ~~ /'in use'/ , 'Checking for registration' )
	  	!! skip( $result.data<success>.defined , 'Checking for registration' );

	sleep 3;
	$result = Zef; 	#Zef.login( 'ⓕⓞⓞ' , 'unicode' , False );
	skip( $result.status == 200 );
	skip( $result.data.defined && $result.data<success>.defined , 'Testing successful login (unicode username)' );

	sleep 3;
	$result = Zef; 	#Zef.login( 'ⓕⓞⓞ' , 'unicode' , False );
	skip( $result.status == 200 );
	skip( $result.data.defined && $result.data<failure>.defined , 'Testing failed login (unicode username)' );
}
=end comment
