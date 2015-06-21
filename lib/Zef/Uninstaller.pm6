module Zef::Uninstaller {

    sub uninstall(
        @modules, 
        CompUnitRepo::Local::Installation $repo = {
            try { mkdir('~/.zef/depot'); };
            .new("~/.zef/depot".IO.abs_path);
        },
        %options?
    ) is export {
        my $removes; 
        my %toremove;
        for @modules -> $module {
            for @($repo.candidates($module)) -> $dist {
                %toremove{$dist<id>} = [];
                for $dist<provides>.keys -> $file {
                    for $dist<provides>{$file}.keys -> $types {
                        my $fpath = $dist<provides>{$file}{$types}<file>;
                        while $fpath.IO !~~ :e && $fpath.chars > 0 {
                            $fpath = $fpath.substr(1);
                        }
                        if $fpath.chars == 0 {
                            die "Couldn't find files for module $module";
                        }
                        %toremove{$dist<id>}.push($fpath);
                    }
                }
            }
        }
        my $manifest = "{$repo.path.Str}/MANIFEST";
        my $jmanif   = from-json($manifest.IO.slurp);
        my @dists    = @($jmanif<dists>);
        my @delid;
        my $index = 0;
        for @dists -> $dist {
            @delid.push($index) if %toremove.exists_key($dist<id>);
            $index++;
        }
        @delid.sort.reverse.map({@dists.splice($_,1);});
        $jmanif<dists> = @dists;
        "{$repo.path.Str}/MANIFEST".IO.spurt(to-json($jmanif));
        for %toremove.keys -> $f { 
            for @(%toremove{$f}) -> $file {
                unlink $file; 
            }
        }
    }
}