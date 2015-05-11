use Zef::Utils::PathTools;
class Zef::Installer;

method install(:$save-to = "$*HOME/.zef/depot", *@metafiles, *%options ) is export {
    try mkdirs($save-to);
    my $repo = CompUnitRepo::Local::Installation.new($save-to);

    my @results = eager gather for @metafiles -> $file {
        my Distribution $dist .= new( |from-json($file.IO.slurp) ) does role { method metainfo {self.hash} };

        KEEP take { ok => 1, $dist.hash.flat };
        UNDO take { ok => 0, $dist.hash.flat };

        unless %options<force> {
            for $repo.candidates($dist.name).list -> $mod {
                if $mod<name> eq $dist.name 
                   && $mod{"ver" | "version"} eq Version.new($dist.vers | $dist.version) 
                   && $mod{"auth" & "author" & "authority"} eq $dist.auth & $dist.author & $dist.authority 
                   {
                    
                    "==> Skipping {$dist.name} already installed ref:<$mod>".say;
                    next;
                }
            }
        } 

        my @provides = gather for $dist.provides.kv -> $name, $file-path {
            my $file-full = $*SPEC.catpath('', $file.IO.dirname, $file-path).IO; # .resolve; <-broke on windows
            my $error     = 'Package attempting to install files outside of repository' if $file-full.absolute !~~ /^ $*CWD /;
            (%options<force> ?? warn $error !! die $error) if $error;
            take $file-full;
        }

        $repo.install(:$dist, @provides);
    }

    return @results;
}
