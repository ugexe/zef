module Zef::Utils;
use JSON::Tiny;


sub recursive_rmdir ( Str $path ) is export {
  return if $path.IO !~~ :e;
  for $path.IO.path.contents -> $tmppath {
    if $tmppath.Str.IO !~~ :d {
      unlink $tmppath.Str;
    } elsif $tmppath.Str.IO ~~ :d {
      recursive_rmdir( $tmppath.Str );
      rmdir $tmppath.Str;
    }
  }
}


sub recursive_copy ( Str $path, Str $destination ) is export {
  for $path.IO.path.contents -> $tmppath {
    if $tmppath.Str.IO !~~ :d {
      copy $tmppath.Str, "{$destination.Str}/$tmppath";
    } elsif $path.Str.IO ~~ :d {
      mkdir "$destination/$tmppath" if "$destination/$tmppath".IO !~~ :e;
      recursive_copy( "{$path.Str}/{$tmppath.Str}" , $destination );
    }
  }
}


sub saveprefs ( Str $home, $prefs ) is export {
  my $fh      = open "$home/.zefrc", :w;
  my $prefstr = to-json( $prefs );
  $prefstr = $prefstr.subst(rx{\}$},  "\n}")\
                     .subst(rx{^\{},  "\{\n\t")\
                     .subst(rx{'",'}, "\",\n\t", :g);
                       
  $fh.say( $prefstr );
  $fh.close;
}


sub getprefs ( Str $home ) is export {
  my $prefs = from-json(($home ~ '/.zefrc').IO ~~ :e ?? slurp $home ~ '/.zefrc' !! '{}');
  $prefs<base> = '/rest'  if !defined $prefs<base>;
  $prefs<host> = 'zef.pm' if !defined $prefs<host>;

  return $prefs;
}


sub gethome ( ) is export {
  my Str $home  = (%*ENV<HOME>        // Nil) 
                ~ (%*ENV<USERPROFILE> // Nil)
                ~ '/.zef';
  die 'Could not locate user\'s home directory.' unless $home ne '/.zef';
  return $home;
}

