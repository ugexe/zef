#!/usr/bin/env perl6

BEGIN {
#following line has unimplemented features and would replace up to @*INC.push..
#  $dynamicinc = "{$?FILE.path.directory}/../lib".IO.path.resolve;
  my $fsflag     = $?FILE.path.index('/') >= 0 ?? '/' !! '\\';
  my $dynamicinc = $?FILE.path.directory.split($fsflag);
  $dynamicinc    = $dynamicinc.splice(0, $dynamicinc.elems -1).join( $fsflag ) ~ "{$fsflag}lib";
  @*INC.push( $dynamicinc );
}
use Zef;

multi sub MAIN('install', *@modules, Bool :$verbose = False) {
  for @modules -> $module {
    my $zef = Zef.install( $module );
    say "Error installing <<$module>>: {$zef.data<error>}" if !$zef.data.defined or $zef.data<error>.defined;
    say "Installed <<$module>>" if $zef.data.defined and not $zef.data<error>.defined;
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
    say "Failed to push module, reason: {$zef.data<error>}";
  } elsif $zef.data.defined && $zef.data<version> {
    say "Successfully pushed module, version: {$zef.data<version>}";
  } else {
    say 'Unknown error';
  }
}

multi sub MAIN('search', *$module, Bool :$verbose) {
  # display a list of modules for a query
  my $zef     = Zef.search( $module );
  my @lengths = 40, 10, 30;
  if $zef.status == 200 && $zef.data ~~ Array {
    @( $zef.data ) ==> map {
      say "{$_<package>}{
            ' 'x(@lengths[0]-$_<package>.chars)
           }{$_<version>}{
            ' 'x(@lengths[1]-$_<version>.chars)
           }{$_<author>}{
            ' 'x(@lengths[2]-$_<author>.chars)
           }{$_<submitted>}";
    } if $zef.data.elems > 0;
    say "No results found for: $module" if $zef.data.elems == 0;
  } else {

#NEED TO DO SOMETHING HERE WITH ERROR HANDLES

    say $zef.perl;
  }
}

multi sub MAIN('login', *$username, *$password, Bool :$verbose) {
  # get a unique key for our username and write to local config
  my $zef = Zef.login( $username , $password );
  if $zef.data ~~ Hash && $zef.data<success>.defined {
    say 'Login was successful';
  } else {
    say ( $zef.data.defined && $zef.data<failure> ??
          $zef.data<reason> !!
          'Unknown error'
        );
  }
}


multi sub MAIN('register', *$username, *$password, Bool :$verbose) {
  # get a unique key for our username and write to local config
  my $zef = Zef.register( $username , $password );
  if $zef.data ~~ Hash && $zef.data<success>.defined {
    say 'Registration was successful';
  } else {
    say ( $zef.data.defined && $zef.data<failure> ??
          $zef.data<reason> !!
          'Unknown error'
        );
  }
}

