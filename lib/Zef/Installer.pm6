class Zef::Installer;
use JSON::Tiny;


method install( *@metafiles, *%options ) is export {
    my CompUnitRepo::Local::Installation $repo = INIT {
        try { mkdir('~/.zef/depot'); };
        .new("~/.zef/depot".IO.absolute);
    }

    META: for @metafiles -> $file {
        my %data = %(from-json($file.IO.slurp));
        if %options<force>.defined:!exists {
            for $repo.candidates(%data<name>).list -> $mod {
                if $mod<name> eq %data<name> 
                   && $mod{"ver" | "version"}  eq Version.new(%data{"vers" | "version"}) 
                   && $mod{"auth" & "author" & "authority"} eq %data{"auth" & "author" & "authority"} {
                    
                    "==> Skipping {%data<name>} already installed ref:<$mod>".say;
                    next META;
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

