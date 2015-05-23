unit class Zef::Installer;
use Zef::Utils::PathTools;

method install(:$save-to = %*CUSTOM_LIB<site>, *@metafiles, *%options) is export {
    try mkdirs($save-to);
    my $repo = CompUnitRepo::Local::Installation.new($save-to);
    my @results = eager gather for @metafiles -> $meta {
        my Distribution $dist .= new( |from-json($meta.IO.slurp) ) does role { method metainfo {self.hash} };
        KEEP take { ok => 1, $dist.hash.flat } and "==> Installed: {$dist.name}".say;
        UNDO take { ok => 0, file => $meta, $dist.hash.flat }

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

        my @pm = gather for $dist.provides.kv -> $name, $file-path {
            my $file-full = $*SPEC.catpath('', $meta.IO.dirname, $file-path).IO; 
            take $file-full;
        }
        my @precomp = $meta.IO.dirname.IO.ls(:r, :f).grep({ $_ ~~ /\.[moarvm|jvm]$/ });

        $repo.install(:$dist, @pm, @precomp);
    }

    return @results;
}
