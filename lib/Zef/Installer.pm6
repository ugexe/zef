class Zef::Installer;
use JSON::Tiny;


method install(
    @metafiles, 
    CompUnitRepo::Local::Installation $repo = {
        try { mkdir('~/.zef/depot'); };
        .new("~/.zef/depot".IO.abs_path);
    },
    *%options
) is export {
    for @metafiles -> $file {
        my %data = %(from-json($file.IO.slurp));
        if !%options.exists_key<force> {
            for @($repo.candidates(%data<name>)) -> $mod {
                if $mod<name> eq %data<name> &&
                   $mod<ver>  eq Version.new(%data.exists_key('vers')    ?? %data<vers> !!
                                 (%data.exists_key('version') ?? %data<version> !!
                                 '')) &&
                   $mod<auth> eq (%data.exists_key('auth') ?? %data<auth> !!
                                 (%data.exists_key('author') ?? %data<author> !!
                                 (%data.exists_key('authority') ?? %data<authority> !!
                                 ''))) {
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

