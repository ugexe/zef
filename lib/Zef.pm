class Zef;
use Zef::Utils;
use Zef::Install;
use Zef::Test;
use Zef::Auth;
use Zef::EZRest;
use JSON::Tiny;


my Str $home = gethome();
unless ( $home.IO ~~ :e ) {
  mkdir $home or die "Couldn't create directory: $home";
  mkdir $home ~ '/src' or die "Couldn't create directory: $home/src";
  mkdir $home ~ '/lib' or die "Couldn't create directory: $home/lib";
};
my $prefs = getprefs( $home );
@*INC.push( $prefs<lib>,"$home/lib" ) if $prefs<lib>.defined;


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
  my $install = Zef::Install.install( module => $module, test => $test);
  return $install;
}	


method push ( ) { 
  if ( 'META.info'.IO ~~ :e ) {
    my $meta = from-json slurp( 'META.info' );
    my %pushdata = (
      key                => $prefs<ukey>,
      meta               => {
        name         => $meta<name>,
        repository   => $meta<source-url>,
        dependencies => $meta<dependencies> || $meta<depends> || Array.new,
      },
    );

    my $req = EZRest.new;
    my $data = $req.req(
      :host\   ( $prefs<host> ),
      :endpoint( $prefs<base> ~ '/push' ),
      :data\   ( to-json( %pushdata ) )
    );
    {
      $data.data = from-json $data.data;
      die 'error' if defined $data<error>;
      CATCH { default { 
        $data = ( error => $data<error> );
      } }
    }
    return $data;
  }
  return ( error => 'No META.info found.' );
}


method search ( Str :$module ) {
  my $req  = EZRest.new;
  my $data = $req.req(
    :host\   ( $prefs<host> ),
    :endpoint( $prefs<base> ~ '/search' ),
    :data\   ( "\{ \"query\" : \"$module\" \}"),
  );

  try {
    $data.data = from-json( $data.data );

    CATCH { default { 
      $data = ( error => $_ );
    } }
  }
  return $data;
}

