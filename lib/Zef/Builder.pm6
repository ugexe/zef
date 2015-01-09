use Zef::Phase::Building;
use JSON::Tiny;

class Zef::Builder does Zef::Phase::Building {

    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            self does ::($p) if do { require ::($p); ::($p).does(Zef::Phase::Building) };
        }
    }

    multi method pre-compile(*@paths is copy) {
        my @dirs = @paths;
        my @modules;
        my @precompiled;
        my %retry-me;

        while @dirs.shift -> $path {
            given $path.IO {
                when :d { for .dir -> $io { @dirs.push: $io } }
                when :f & /\.pm6?$/ { @modules.push($_) }
            }            
        }

        while @modules.shift -> $module {
        #for @modules -> $module {
            my $precomp-path = $module.path ~ '.' ~ $*VM.precomp-ext;
            try { $precomp-path.IO.unlink } if $precomp-path.IO.e;
            

            say "";
            say "---DEBUG precomp---";
            CompUnit.new($module.path, :INC(@dirs) ).precomp;

            say $precomp-path;
            my $precomp-result = $precomp-path.IO.e;

            if $precomp-result {
                @precompiled.push($precomp-path);
                say "precomp ok";
            }
            else {
                # this is bad and i should feel bad
                # todo: build dependency tree instead
                %retry-me{$module}++;
                @modules.push($module) if %retry-me{$module} <= 3;
                

                say "precomp not ok";
            }

            say "---/DEBUG precomp---";
            say "";

        }

        return @precompiled;
    }
}