#!/usr/bin/env perl6

#use Zef;
use lib './lib';
use EZRest;
use JSON::Tiny;


my $home ~= %*ENV<HOME> if defined %*ENV<HOME>; 
$home ~= %*ENV<USERPROFILE> if defined %*ENV<USERPROFILE>;
$home ~= '/.ppac';
die 'Could not locate user\'s home directory.' unless $home ne '/.ppac';

unless ( $home.IO ~~ :e ) {
  mkdir $home or die "Couldn't create directory: $home";
  mkdir $home ~ '/src' or die "Couldn't create directory: $home/src";
  mkdir $home ~ '/lib' or die "Couldn't create directory: $home/lib";
};

#my %args = @*ARGS;

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

multi sub MAIN('login', *$username, *$password, Bool :$verbose) {
  # get a unique key for our username and write to local config
  my $req = EZRest.new;
  say from-json($req.req( 
    :data( "\{ \"username\" : \"$username\" , \"password\" : \"$password\" \}"),
    :endpoint( '/rest/login' )
   ).data).perl; 
}


multi sub MAIN('register', *$username, *$password, Bool :$verbose) {
  # get a unique key for our username and write to local config
  my $req = EZRest.new;
  say $req.req( 
    :data(     "\{ \"username\" : \"$username\" , \"password\" : \"$password\" \}"),
    :endpoint( '/rest/register' )
   ); 
}
