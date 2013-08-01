#!/usr/bin/env perl6

BEGIN {
#following line has unimplemented features and would replace up to @*INC.push..
#  $dynamicinc = "{$?FILE.path.directory}/../lib".IO.path.resolve;
  my $fsflag     = $?FILE.path.directory.index('/') >= 0 ?? '/' !! '\\';
  my $dynamicinc = $?FILE.path.directory.split($fsflag);
  $dynamicinc.pop();
  $dynamicinc = $dynamicinc.join( $fsflag );
  $dynamicinc ~= ( $dynamicinc.substr(0, 1) eq '.' or $dynamicinc.substr(0, 1) eq $fsflag ?? $fsflag !! '') ~ 'lib';
  @*INC.push( $dynamicinc );
}
use EZRest;
use JSON::Tiny;


my $home ~= %*ENV<HOME> if defined %*ENV<HOME>; 
$home ~= %*ENV<USERPROFILE> if defined %*ENV<USERPROFILE>;
$home ~= '/.zef';
die 'Could not locate user\'s home directory.' unless $home ne '/.zef';

unless ( $home.IO ~~ :e ) {
  mkdir $home or die "Couldn't create directory: $home";
  mkdir $home ~ '/src' or die "Couldn't create directory: $home/src";
  mkdir $home ~ '/lib' or die "Couldn't create directory: $home/lib";
};

my $prefs = from-json(($home ~ '/.zefrc').IO ~~ :e ?? slurp $home ~ '/.zefrc' !! '{}');
$prefs<base> = '/rest'  if !defined $prefs<base>;
$prefs<host> = 'zef.pm' if !defined $prefs<host>;

sub recursive_rmdir ( $path ) {
  return if $path.IO !~~ :e;
  for $path.IO.path.contents -> $tmppath {
    if $tmppath.Str.IO ~~ :f {
      unlink $tmppath.Str;
    } elsif $tmppath.Str.IO ~~ :d {
      recursive_rmdir( $tmppath.Str );
      rmdir $tmppath.Str;
    }
  }
};

sub recursive_copy ( $path, $destination ) {
  for $path.IO.path.contents -> $tmppath {
    if $tmppath.Str.IO ~~ :f {
      $tmppath.copy( "{$destination.Str}/$tmppath" );
    } elsif $path.Str.IO ~~ :d {
      mkdir "$destination/$tmppath" if "$destination/$tmppath".IO !~~ :e;
      recursive_copy( "{$path.Str}/{$tmppath.Str}" , $destination );
    }
  }
}

multi sub MAIN('install', *@modules, Bool :$verbose = False) {
  for @modules -> $module {
    #say $module if :$verbose;
    #Zef.install($module)
    #  ??say "installation for $module successful"
    #  !!say "installatoin for $module failed";      
    # go to perl eco system and download meta file
    # check EVERY fucking repo's meta file for it's module name and store them in a hash with TLD edit distance, push matching distances into hash (dont override last entry)
    # if %hash{0}, then download that modules repo
    # if !%hash{0}.exists and %hash{$lowest_num} = $module, suggest module to user. if %hash{$loweset_num} = @modules, suggest them all
    # This will all be slow as shit, especially the module naming suggesting. No need to TLD if an exact match is found, so dont run TLD until all names are stored.
    # Save the module to whatever directory
    my $req = EZRest.new;
    for @modules -> $module {
      my $data = $req.req(
        :host(     $prefs<host> ),
        :endpoint( $prefs<base> ~ '/download' ),
        :data(     "\{ \"name\" : \"$module\" \}"),
      );
      $data = from-json( $data.data );
      chdir $home ~ "/src";
      my $clone = "git clone \"{$data<repo>}\" \"{$module.subst('::','_')}\"";
      my $revrt = "git checkout \"{$data<commit>}\"";
      recursive_rmdir( $module.subst('::', '_') );
      qqx{$clone}; 
      chdir "{$module.subst('::', '_')}";
      qqx{$revrt};
      say "ERROR: No lib/ directory found for $module" , next if "lib".IO !~~ :e;
      chdir "lib";
      recursive_copy  '.', "$home/lib";
      say "$module was successfully installed to: $home/lib/";
    }
  }
}

multi sub MAIN('uninstall', *@modules, Bool :$verbose) {
  for @modules -> $module {
    say $module if :$verbose;

    # First, we need to make sure we are uninstalling from the proper place
    # i.e. if we are using a local-lib

    # Delete module, upload local db
  }
}

multi sub MAIN('push', Bool :$verbose) {
  # Open local meta.info file and read info
  # Get latest commit id from repo in meta.info
  # Save git to latest commit id with version and authority
  if ( 'META.info'.IO ~~ :e ) {
    my $meta = from-json slurp( 'META.info' );
    my %pushdata;
    %pushdata<key>                = $prefs<ukey>;
    %pushdata<meta>               = { };
    %pushdata<meta><name>         = $meta<name>;
    %pushdata<meta><repository>   = $meta<source-url>;
    %pushdata<meta><dependencies> = $meta<dependencies>;
    my $req = EZRest.new;
    my $data = $req.req(
      :host(     $prefs<host> ),
      :endpoint( $prefs<base> ~ '/push' ),
      :data(     to-json( %pushdata ) )
    );
    $data = from-json $data.data;
    say 'Pushed package \'' ~ $meta<name> ~ '\' version: ' ~ $data<version> if not defined $data<error>;
    say 'Error: ' ~ $data<error> if defined $data<error>;
  } else { 
    say 'Could not find META.info';
  }
}

multi sub MAIN('search', *$module, Bool :$verbose) {
  # display a list of modules for a query
  my $req  = EZRest.new;
  my $data = $req.req(
    :host(     $prefs<host> ),
    :endpoint( $prefs<base> ~ '/search' ),
    :data(     "\{ \"query\" : \"$module\" \}"),
  );


  $data = from-json( $data.data );

  if @( $data ).elems == 0 or @( $data ) !~~ Array {
    say 'No results.';
    return;
  }
  for @( $data ) -> $hash {
    say "{$hash<package>}\t\t\t{$hash<version>}\t\t{$hash<submitted>} by {$hash<author>}";
  }
}

multi sub MAIN('login', *$username, *$password, Bool :$verbose) {
  # get a unique key for our username and write to local config
  my $req  = EZRest.new;
  my $data = from-json($req.req( 
    :host(     $prefs<host> ),
    :endpoint( $prefs<base> ~ '/login' ),
    :data(     "\{ \"username\" : \"$username\" , \"password\" : \"$password\" \}"),
  ).data);

  if defined $data<success> && $data<success> eq '1' {
    $prefs<ukey> = $data<newkey>;
    saveprefs;
    say 'Success.';
  } else {
    say $data<reason>;
  }
}


multi sub MAIN('register', *$username, *$password, Bool :$verbose) {
  # get a unique key for our username and write to local config
  my $req  = EZRest.new;
  my $data = $req.req( 
    :host(     $prefs<host> ),
    :endpoint( $prefs<base> ~ '/register' ),
    :data(     "\{ \"username\" : \"$username\" , \"password\" : \"$password\" \}"),
  ).data;
  $data = from-json( $data );

  if defined $data<success> && $data<success> eq '1' {
    $prefs<ukey> = $data<newkey>;
    saveprefs;
    say 'Success.';
  } else {
    say $data<reason>;
  }
}

sub saveprefs ( ) {
  my $fh = open "$home/.zefrc", :w;
  $fh.say( to-json( $prefs ) );
  $fh.close;
};
