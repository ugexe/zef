class Zef::Search;
use Zef::Utils;
use Zef::EZRest;
use JSON::Tiny;


my Str $home  = gethome();
my $prefs = getprefs( $home );


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
