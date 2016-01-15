use Zef;
use Zef::Distribution;
use Zef::Config;

my %CONFIG = ZEF-CONFIG();

class Zef::ContentStorage::LocalCache does ContentStorage {
    has $.mirrors;
    has $.auto-update;
    has $.fetcher is rw;
    has $.cache is rw;
    has $.dir = "{%CONFIG<Store>}/store";

    method IO {
        my $dir = $.dir.IO;
        $dir.mkdir unless $dir.e;
        $dir;
    }

    method !gather-metas($path, :@identities, Int :$max-recursion = 3){
        return @() if $max-recursion <= 0;
        my @dirs;
        for $path.dir -> $dir {
            next if $dir.basename eq '.git';
            if $dir.basename ~~ /^ 'META' '6'? '.' ['json'|'info'] $/ {
                my $json = from-json($dir.slurp);
                @dirs.append(Zef::Distribution.new(|%($json))), next 
                    if $json<name> eq any @identities;
                for $json<provides>.keys -> $prov {
                    @dirs.append(Zef::Distribution.new(|%($json))), next
                        if $prov eq any @identities;
                }
            }
            @dirs.append(
                self!gather-metas(
                    $dir, 
                    :@identities, 
                    :max-recursion($max-recursion-1)
                )
            ) if $dir.d;
        }
        @dirs.grep(*.defined).cache;
    }

    # todo: handle %fields
    method search(:$max-results = 5, *@identities, *%fields) {
        #more efficient to do identities as we parse the json - (1 loop instead of 2)
        my @distros = self!gather-metas($.dir.IO, :@identities);
    }
}
