class Zef::Install;
use Zef::Utils;
use Zef::Test;
use Zef::EZRest;
use JSON::Tiny;


my Str $home  = gethome();
my $prefs = getprefs( $home );


method install ( Str :$module, Bool :$test = True ) {
  my $req = EZRest.new;
  my $data = $req.req(
  :host\   ( $prefs<host> ),
    :endpoint( $prefs<base> ~ '/download' ),
    :data\   ( "\{ \"name\" : \"$module\" \}"),
  );
  {
    $data.data = from-json( $data.data );
    my @unsatisfieddepends;
    my @satisfieddepends;

    if $data.data<dependencies>.defined && $data.data<dependencies> ~~ Hash {
      for %( $data.data<dependencies> ).keys -> Str $t {
        require ::($t);
        @satisfieddepends.push( $t );
        CATCH { default { 
          @unsatisfieddepends.push( $t );
        } }
      }
      return { error => 'Unsatisfied dependencies' , unsat => @unsatisfieddepends , sat => @satisfieddepends } if @unsatisfieddepends.elems > 0;
    }
    
    die "Module not found in zef: $module" if !$data.data<repo>.defined;
    chdir $home ~ "/src";
    my $clone = "git clone \"{$data.data<repo>}\" \"{$module.subst('::','_')}\"";
    my $revrt = "git checkout \"{$data.data<commit>}\"";
    recursive_rmdir( "$home/src/{$module.subst('::', '_')}" );
    qqx{$clone}; 
    chdir "{$module.subst('::', '_')}";
    qqx{$revrt};
    die "ERROR: No 'lib/' directory found for $module" , next if "lib".IO !~~ :e;

    if $test  { die "Failed to install $module" unless Zef::Test.test( module => $module ); }

    chdir "lib";
    recursive_copy  '.', $prefs<lib> || "$home/lib";

    CATCH { default { 
      my %hash =  error => $_ ;
      $data = %hash;
    } }
  }
  return $data;
}
