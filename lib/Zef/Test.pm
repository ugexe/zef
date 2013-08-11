class Zef::Test;
use Zef::Utils;
use Zef::EZRest;
use JSON::Tiny;


my Str $home  = gethome();
my $prefs = getprefs( $home );


method test ( Str :$module ) {
  my $req = EZRest.new;
  my $data = $req.req(
  :host\   ( $prefs<host> ),
    :endpoint( $prefs<base> ~ '/download' ),
    :data\   ( "\{ \"name\" : \"$module\" \}"),
  );
  $data.data = from-json( $data.data );
  
  my $test = 'prove -e \'perl6 -Ilib\' t/';
  $test    = qqx{$test}.trim;
  #report information
  my %testhash = {
    package       => $module,
    results       => $test,
    os            => $*OS,
    perlversion   => $*PERL,
    #moduleversion => $data.data<commit>,
    tester        => $prefs<ukey>
  };


  my $reporthash = to-json(%testhash);
  my $reportdata = $req.req(
    :host\   ( $prefs<host> ),
    :endpoint( $prefs<base> ~ '/testresult' ),
    :data\   ( $reporthash )
  );
        
  return ($test !~~ rx{"\nResult: PASS"})??0!!1;
}
