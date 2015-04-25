class Zef::Installer;

method install(:$save-to = "$*HOME/.zef/depot", *@metafiles, *%options ) is export {
    try mkdir($save-to);
    my $repo = CompUnitRepo::Local::Installation.new($save-to);

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

        my @provides;
        for @(%data<provides>) -> $pair is copy {
          $pair.value = $*SPEC.catpath('', $file.IO.dirname, $pair.value).IO.resolve;
          die 'Package attempting to install files outside of repository' if $pair.value !~~ /^ $*CWD /;
          @provides.push($pair.values);
        }

        $repo.install(
            dist => class :: {
                        method metainfo { 
                            %data;
                        }
                    },
            @provides,
        ) or die "Unable to install $file in $repo";
    }
}

