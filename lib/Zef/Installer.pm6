module Zef::Installer;
use JSON::Tiny;

sub install(
  @metafiles, 
  CompUnitRepo::Local::Installation $repo = .new("~/.zef/depot".IO.abs_path)
) is export {
  for @metafiles -> $file {
    my %data = %(from-json($file.IO.slurp));
    $repo.install(
      dist => class :: {
                method metainfo { 
                  %data;
                }
              },
      |%data<provides>.values,
    ) or die "Unable to install $file";
  }
}
