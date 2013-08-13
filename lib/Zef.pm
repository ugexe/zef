
use Zef::Auth;
use Zef::Install;
use Zef::Push;
use Zef::Search;
use Zef::Test;

use Zef::Utils;
use JSON::Tiny;


my Str $home = gethome();
unless ( $home.IO ~~ :e ) {
  mkdir $home or die "Couldn't create directory: $home";
  mkdir $home ~ '/src' or die "Couldn't create directory: $home/src";
  mkdir $home ~ '/lib' or die "Couldn't create directory: $home/lib";
};
my $prefs = getprefs( $home );
@*INC.push( $prefs<lib>,"$home/lib" ) if $prefs<lib>.defined;

class Zef {
  method register ( Str :$username, Str :$password , Bool :$autoupdate = True ) {
    my $register = Zef::Auth.register( username => $username, password => $password, autoupdate => $autoupdate );
    return $register;
  }


  method login ( Str :$username, Str :$password , Bool :$autoupdate = True ) {
    my $login = Zef::Auth.login( username => $username, password => $password, autoupdate => $autoupdate );
    return $login;
  }


  method install ( Str :$module, Bool :$test = True ) {
    # test should be done outside of .install, also method test for just testing
    # [i.e.] if $test { return 'test failed' unless Zef::Test.test( module => $module) }; return Zef::Install.install( module => $module);
    # This will require splitting the module fetching out of the Install module, so test can be sent a target without calling .install
    my $install = Zef::Install.install( module => $module, test => $test);
    return $install;
  }	


  method test ( Str :$module ) {
    my $test = Zef::Test.test( module => $module );
    return $test??'Tests passed'!!'TESTS FAILED';
  } 


  method push ( ) { 
    my $data = Zef::Push.push( );
    return $data;
  }


  method search ( Str :$module ) {
    my $data = Zef::Search.search( module => $module );
    return $data;
  }

}

sub prefix:<zef> (Str $package, Str :$ver?, Str :$auth?) is export {
  say "zeffing $package, $ver, $auth";
  require ::($package);
}
