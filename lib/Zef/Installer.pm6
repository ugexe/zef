class Zef::Installer;
use JSON::Tiny;

# hacky until $*HOME works properly in core
BEGIN our $HOME = # $*HOME = homedir(
    ($*DISTRO.is-win
        ?? $*SPEC.catpath(%*ENV<HOMEDRIVE>, %*ENV<HOMEPATH>,'')
        !! $*SPEC.catpath('', %*ENV<HOME>,''));
#);

method install(:$save_to = "$HOME/.zef/depot", *@metafiles, *%options ) is export {
    try { mkdir($save_to) };
    my $repo = CompUnitRepo::Local::Installation.new($save_to);

    for @metafiles -> $file {
        my %data = %(from-json($file.IO.slurp));
        unless %options<force> {
            for $repo.candidates(%data<name>).list -> $mod {
                if $mod<name> eq %data<name> 
                   && $mod{"ver" | "version"} eq Version.new(%data{"vers" | "version"}) 
                   && $mod{"auth" & "author" & "authority"} eq %data{"auth" & "author" & "authority"} 
                   {
                    
                    "==> Skipping {%data<name>} already installed ref:<$mod>".say;
                    next;
                }
            }
        } 

        $repo.install(
            dist => class :: {
                        method metainfo { 
                            %data;
                        }
                    },
            |%data<provides>.values,
        ) or die "Unable to install $file in $repo";
    }
}

