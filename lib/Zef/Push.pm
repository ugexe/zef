class Zef::Push;
use Zef::Utils;
use Zef::EZRest;
use JSON::Tiny;


my Str $home  = gethome();
my $prefs = getprefs( $home );


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
