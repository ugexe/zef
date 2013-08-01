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

  method register ( $username , $password , Bool $autoupdate = True ) {
    my $req  = EZRest.new;
    my $data = $req.req( 
      :host\   ( $prefs<host> ),
      :endpoint( $prefs<base> ~ '/register' ),
      :data\   ( "\{ \"username\" : \"$username\" , \"password\" : \"$password\" \}"),
    );
    
    {
      $data.data = from-json( $data.data );
      if defined $data<success> && $data<success> eq '1' {
        $prefs<ukey> = $data<newkey>;
        saveprefs if $autoupdate;
      }
      CATCH { default {
        #ignore the error
      } }
    }
    return $data;
  }

  method login ( $username , $password , Bool $autoupdate = True ) {
    my $req  = EZRest.new;
    my $data = $req.req( 
      :host\   ( $prefs<host> ),
      :endpoint( $prefs<base> ~ '/login' ),
      :data\   ( "\{ \"username\" : \"$username\" , \"password\" : \"$password\" \}"),
    );
    {
      $data.data = from-json( $data.data );
      if defined $data<success> && $data<success> eq '1' {
        $prefs<ukey> = $data<newkey>;
        saveprefs if $autoupdate;
      }
      CATCH { default { 
        #ignore the error
      } }
    }
    return $data;
  }

	method install ( $module ) {
		# install shit
    my $req = EZRest.new;
    my $data = $req.req(
      :host\   ( $prefs<host> ),
      :endpoint( $prefs<base> ~ '/download' ),
      :data\   ( "\{ \"name\" : \"$module\" \}"),
    );
    {
      $data.data = from-json( $data.data );
      chdir $home ~ "/src";
      my $clone = "git clone \"{$data.data<repo>}\" \"{$module.subst('::','_')}\"";
      my $revrt = "git checkout \"{$data.data<commit>}\"";
      recursive_rmdir( $module.subst('::', '_') );
      qqx{$clone}; 
      chdir "{$module.subst('::', '_')}";
      qqx{$revrt};
      die "ERROR: No lib/ directory found for $module" , next if "lib".IO !~~ :e;
      chdir "lib";
      recursive_copy  '.', "$home/lib";

      CATCH { default { 
        #ignore the error
        say $_;
        $data = { error => $_ , module => $module };
      } }
    }
    return $data;
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
        :host\   ( $prefs<host> ),
        :endpoint( $prefs<base> ~ '/push' ),
        :data\   ( to-json( %pushdata ) )
      );
      {
        $data.data = from-json $data.data;
        die 'error' if defined $data<error>;
        CATCH { default { 
          $data = { error => $data<error> };
        } }
      }
      return $data;
    }
    return { error => 'No META.info found.' };
  }
  
  method search ( $module ) {
    my $req  = EZRest.new;
    my $data = $req.req(
      :host\   ( $prefs<host> ),
      :endpoint( $prefs<base> ~ '/search' ),
      :data\   ( "\{ \"query\" : \"$module\" \}"),
    );

    try {
      $data.data = from-json( $data.data );

      die 'No results found' if @( $data.data ).elems == 0 or @( $data.data ) !~~ Array;

      CATCH { default { 
        $data = { error => $_ };
      } }
    }
    return $data;
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
