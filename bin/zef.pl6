#!/usr/bin/env perl6

BEGIN {
#following line has unimplemented features and would replace up to @*INC.push..
#  $dynamicinc = "{$?FILE.path.directory}/../lib".IO.path.resolve;
  my $fsflag     = $?FILE.path.index('/') >= 0 ?? '/' !! '\\';
  my $dynamicinc = $?FILE.path.directory.split($fsflag);
  $dynamicinc    = $dynamicinc.splice(0, $dynamicinc.elems -1).join( $fsflag ) ~ "{$dynamicinc.IO.path.is-relative ?? '' !! $fsflag}lib";
  @*INC.push( $dynamicinc );
}
use Zef;

multi sub MAIN('install', *@modules, Bool :$verbose = False) {
  Zef.install( @modules );
}

multi sub MAIN('uninstall', *@modules, Bool :$verbose) {
  #Zef.uninstall( @modules );
  say 'Not implemented, yet.';
}

multi sub MAIN('push', Bool :$verbose) {
  # Open local meta.info file and read info
  # Get latest commit id from repo in meta.info
  # Save git to latest commit id with version and authority
  Zef.push;
}

multi sub MAIN('search', *$module, Bool :$verbose) {
  # display a list of modules for a query
  Zef.search( $module );
}

multi sub MAIN('login', *$username, *$password, Bool :$verbose) {
  # get a unique key for our username and write to local config
  Zef.login( $username , $password );
}


multi sub MAIN('register', *$username, *$password, Bool :$verbose) {
  # get a unique key for our username and write to local config
  Zef.register( $username , $password );
}

