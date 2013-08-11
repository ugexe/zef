class Zef::Test;
use Zef::Utils;
use Zef::EZRest;
use JSON::Tiny;


my Str $home  = gethome();
my $prefs = getprefs( $home );


method test ( $module ) {
  my $test = 'prove -e \'perl6 -Ilib\' t/';
  $test    = qqx{$test}.trim;
  #report information
  my %testhash = {
    package       => $module,
    results       => $test,
    os            => $*OS,
    perlversion   => $*PERL,
    #moduleversion => $data.data<commit>,
    #tester        => $prefs<ukey>
  };


  my $report = EZRest.new;
  my $reporthash = to-json(%testhash);
  my $reportdata = $report.req(
    :host\   ( $prefs<host> ),
    :endpoint( $prefs<base> ~ '/testresult' ),
    :data\   ( $reporthash )
  );
        
  return ($test !~~ rx{"\nResult: PASS"})??0!!1;
}
