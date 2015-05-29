use Zef::Utils::PathTools;

class Zef::Installer {
    method install(:$save-to = %*CUSTOM_LIB<site>, *@metafiles, *%options) is export {
        try mkdirs($save-to);
        my $repo = CompUnitRepo::Local::Installation.new($save-to);

        my @results = eager gather for @metafiles -> $meta {
            my Distribution $dist .= new( |from-json($meta.IO.slurp) ) does role { method metainfo {self.hash} };
            my %result = %(module => $dist.name, file => $meta, $dist.hash.flat); 
            KEEP %result<ok> = 1;
            UNDO %result<ok> = 0;
            POST take { %result }

            unless %options<force> {
                for $repo.candidates($dist.name).list -> $mod {
                    if $mod<name> eq $dist.name 
                       && (($mod<ver> // $mod<version>) eq (Version.new($dist.ver // $dist.version))) 
                       && ( ( ($mod<auth> && $dist.auth) && ($mod<auth> eq $dist.auth) )
                            || ("{$mod<author> // ''}:{$mod<authority> // ''}" eq "{$dist.author // ''}:{$dist.authority // ''}")
                        )
                       {
                        %result<skipped> = 1 andthen next;
                    }
                }
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
}