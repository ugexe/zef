#!/usr/bin/env perl6
use v6;

BEGIN {
#following line has unimplemented features and would replace up to @*INC.push..
#  $dynamicinc = "{$?FILE.path.directory}/../lib".IO.path.resolve;
  my $fsflag     = $?FILE.path.index('/') >= 0 ?? '/' !! '\\';
  my $dynamicinc = $?FILE.path.directory.split($fsflag);
  $dynamicinc    = $dynamicinc.splice(0, $dynamicinc.elems -1).join( $fsflag ) ~ "{$fsflag}lib";
  @*INC.push( $dynamicinc );
}
use lib 'lib';
use Zef;

my $colorlookup = { black => 30, red => 31, green => 32, yellow => 33, blue => 34, magenta => 35, cyan => 36, white => 37 };
sub color ( Str $s , $color is copy ) {
  $color = $colorlookup{$color} if $color !~~ rx{\d+};
  return "\o33[0;{$color}m{$s}\o33[0;{$colorlookup<white>}m";
}

multi sub MAIN('install', *@modules, Bool :$verbose = False) {
  while @modules.elems > 0 && my Str $module = @modules.shift {
    say "[{color 'INFO', 'blue'} ]: Downloading META data for $module";
    my $zef = Zef.install( $module );
    if $zef<error>.defined {
      if $zef<unsat>.defined {
        @modules.unshift( $module );
        for @( $zef<unsat> ) -> Str $m {
          @modules.unshift( $m ); 
          say "[{color 'INFO', 'blue'} ]: $module depends on $m, downloading...";
        }
        next;
      } else {
        say "[{color 'ERROR', 'red'}]: {$zef<error>.Str}";
        return;
      }
    }
    say "[{color 'ERROR', 'red'}]: Error installing <<$module>>: {$zef<error>}" if $zef<error>.defined;
    say "[{color 'INFO', 'green'} ]: Installed <<$module>>" if not $zef<error>.defined && $zef.data.defined;
  }
}

multi sub MAIN('uninstall', *@modules, Bool :$verbose) {
  #Zef.uninstall( @modules );
  say 'Not implemented, yet.';
}

multi sub MAIN('push', Bool :$verbose) {
  # Open local meta.info file and read info
  # Get latest commit id from repo in meta.info
  # Save git to latest commit id with version and authority
  my $zef = Zef.push;
  if $zef.data.defined && $zef.data<error>.defined {
    say "[{color 'ERROR', 'red'}]: Failed to push module, reason: {$zef.data<error>}";
  } elsif $zef.data.defined && $zef.data<version> {
    say "[{color 'INFO', 'green'} ]: Successfully pushed module, version: {$zef.data<version>}";
  } else {
    say "[{color 'ERROR', 'red'}]: Unknown error";
  }
}

multi sub MAIN('search', *$module, Bool :$verbose) {
  # display a list of modules for a query
  my $zef     = Zef.search( $module );
  my @lengths = 40, 10, 30;
  if $zef.status == 200 && $zef.data ~~ Array {
    @( $zef.data ) ==> map {
      my $INSTALLFLAG = ' ';
      {
        require ::($_<package>);
        $INSTALLFLAG = 'i';
        CATCH { default { } }
      }
      say "({$INSTALLFLAG})  {$_<package>}{
            ' 'x(@lengths[0]-$_<package>.chars)
           }{$_<version>}{
            ' 'x(@lengths[1]-$_<version>.chars)
           }{$_<author>}{
            ' 'x(@lengths[2]-$_<author>.chars)
           }{$_<submitted>}";
    } if $zef.data.elems > 0;
    say "[{color 'WARN', 'yellow'} ]: No results found for: $module" if $zef.data.elems == 0;
  } else {

#NEED TO DO SOMETHING HERE WITH ERROR HANDLES

    say $zef.perl;
  }
}

multi sub MAIN('login', *$username, *$password, Bool :$verbose) {
  # get a unique key for our username and write to local config
  my $zef = Zef.login( $username , $password );
  if $zef.data ~~ Hash && $zef.data<success>.defined {
    say "[{color 'INFO', 'green'} ]: Login was successful";
  } else {
    say "[{color 'ERROR', 'red'}]: " ~ ( $zef.data.defined && $zef.data<failure> ??
          $zef.data<reason> !!
          'Unknown error'
        );
  }
}


multi sub MAIN('register', *$username, *$password, Bool :$verbose) {
  # get a unique key for our username and write to local config
  my $zef = Zef.register( $username , $password );
  if $zef.data ~~ Hash && $zef.data<success>.defined {
    say "[{color 'INFO', 'green'} ]: Registration was successful";
  } else {
    say "[{color 'ERROR', 'red'}]: " ~ ( $zef.data.defined && $zef.data<failure> ??
          $zef.data<reason> !!
          'Unknown error'
        );
  }
}

multi sub MAIN('flex') {
  print q{
ZEF, UNLEASH!
    
@@@@@@@@@@@@@@@@@@@@@**^^""~~~"^@@^*@*@@**@@@@@@@@@
@@@@@@@@@@@@@*^^'"~   , - ' '; ,@@b. '  -e}~color('`', 'yellow')~q{@@@@@@@@
@@@@@@@@*^"~      . '     . ' ,@@@@(  e@*@@@@@@@@@@
@@@@@^~         .       .   ' @@@@@@, ~^@@@@@@@@@@@
@@@~ ,e**@@*e,  ,e**e, .    ' '@@@@@@e,  "*@@@@@'^@
@',e@@@@@@@@@@ e@@@@@@       ' '*@@@@@@    @@@'   0
@@@@@@@@@@@@@@@@@@@@@',e,     ;  ~^*^'    ;^~   ' 0
@@@@@@@@@@@@@@@^""^@@e@@@   .'           ,'   .'  @
@@@@@@@@@@@@@@'    '@@@@@ '         ,  ,e'  .    ;@
@@@@@@@@@@@@@' ,&&,  ^@*'     ,  .  i^"@e, ,e@e  @@
@@@@@@@@@@@@' ,@@@@,          ;  ,& !,,@@@e@@@@ e@@
@@@@@,~*@@*' ,@@@@@@e,   ',   e^~^@,   ~'@@@@@@,@@@
@@@@@@, ~" ,e@@@@@@@@@*e*@*  ,@e  @@""@e,,@@@@@@@@@
@@@@@@@@ee@@@@@@@@@@@@@@@" ,e@' ,e@' e@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@" ,@" ,e@@e,,@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@~ ,@@@,,0@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@,,@@@@@@@@@@@@@@@@@@@@@@@@@
};

}
