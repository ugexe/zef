#!/usr/bin/env perl6

#use Zef;
use lib './lib';
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

multi sub MAIN('install', *@modules, Bool :$verbose) {
  for @modules -> $module {
    say $module if :$verbose;
    #Zef.install($module)
    #  ??say "installation for $module successful"
    #  !!say "installatoin for $module failed";      
    # go to perl eco system and download meta file
    # check EVERY fucking repo's meta file for it's module name and store them in a hash with TLD edit distance, push matching distances into hash (dont override last entry)
    # if %hash{0}, then download that modules repo
    # if !%hash{0}.exists and %hash{$lowest_num} = $module, suggest module to user. if %hash{$loweset_num} = @modules, suggest them all
    # This will all be slow as shit, especially the module naming suggesting. No need to TLD if an exact match is found, so dont run TLD until all names are stored.
    # Save the module to whatever directory
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

  say 'No results.' if @( $data ).elems == 0;
  for @( $data ) -> $hash {
    say $hash.perl;
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
