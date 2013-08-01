#!/usr/bin/env perl6

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

class Zef {

  method register ( $username , $password ) {
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

  method login ( $username , $password ) {
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

	method install ( @modules ) {
		# install shit
    my $req = EZRest.new;
    for @modules -> $module {
      my $data = $req.req(
        :host\   ( $prefs<host> ),
        :endpoint( $prefs<base> ~ '/download' ),
        :data\   ( "\{ \"name\" : \"$module\" \}"),
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

  method push ( ) { 
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
  
  method search ( $module ) {
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

  sub saveprefs ( ) {
    my $fh = open "$home/.zefrc", :w;
    $fh.say( to-json( $prefs ) );
    $fh.close;
  }
}
