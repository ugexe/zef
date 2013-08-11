class Zef::Auth;
use Zef::Utils;
use Zef::EZRest;
use JSON::Tiny;


my $prefs = getprefs( gethome() );


method login ( Str :$username, Str :$password, Bool :$autoupdate = True ) {
  my $req  = EZRest.new;
  my $data = $req.req( 
    :host\   ( $prefs<host> ),
    :endpoint( $prefs<base> ~ '/login' ),
    :data\   ( "\{ \"username\" : \"$username\" , \"password\" : \"$password\" \}"),
  );
  {
    $data.data = from-json( $data.data );
    if defined $data.data<success> && $data.data<success> eq '1' {
      $prefs<ukey> = $data.data<newkey>;
      saveprefs($prefs) if $autoupdate;
    }
    CATCH { default { 
      #ignore the error
    } }
  }
  return $data;
}


method register ( Str :$username, Str :$password, Bool :$autoupdate = True ) {
  my $req  = EZRest.new;
  my $data = $req.req( 
    :host\   ( $prefs<host> ),
    :endpoint( $prefs<base> ~ '/register' ),
    :data\   ( "\{ \"username\" : \"$username\" , \"password\" : \"$password\" \}"),
  );
  
  {
    $data.data = from-json( $data.data );
    if defined $data.data<success> && $data.data<success> eq '1' {
      $prefs<ukey> = $data.data<newkey>;
      saveprefs($prefs) if $autoupdate;
    }
    CATCH { default {
      #ignore the error
    } }
  }
  return $data;
}
