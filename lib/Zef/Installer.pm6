unit class Zef::Installer;
use Zef::Utils::PathTools;

method install(:$save-to = "$*HOME/.zef/depot", *@metafiles, *%options ) is export {
    try mkdirs($save-to);
    my $repo = CompUnitRepo::Local::Installation.new($save-to);

    my @results = eager gather for @metafiles -> $file {
        my Distribution $dist .= new( |from-json($file.IO.slurp) ) does role { method metainfo {self.hash} };

        KEEP take { ok => 1, $dist.hash.flat } and "==> Installed: {$dist.name}".say;
        UNDO take { ok => 0, $dist.hash.flat };

        unless %options<force> {
            next if $repo.candidates($dist.name).list.grep(-> $mod {
                if $mod<name> eq $dist.name 
                   && (($mod<ver> // $mod<version>) eq (Version.new($dist.ver // $dist.version))) 
                   && ( ( ($mod<auth> && $dist.auth) && ($mod<auth> eq $dist.auth) )
                        || ("{$mod<author> // ''}:{$mod<authority> // ''}" eq "{$dist.author // ''}:{$dist.authority // ''}")
                    )
                   {
                    "==> Skipping {$dist.name} already installed ref:<{$mod<id>}>".say;
                }
            });
        } 

        my @provides = gather for $dist.provides.kv -> $name, $file-path {
            my $file-full = $*SPEC.catpath('', $file.IO.dirname, $file-path).IO; # .resolve; <-broke on windows
            take $file-full;
        }

        $repo.install(:$dist, @provides);
    }

    return @results;
}
