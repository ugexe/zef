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

        while @dirs.shift -> $path {
            given $path.IO {
                when :d { for .dir -> $io { @dirs.push: $io } }
                when :f & /\.pm6?$/ { @modules.push($_) }
            }            
        }

        for @modules -> $module {
            my $precomp-path = $module.path ~ '.' ~ $*VM.precomp-ext;
            try { $precomp-path.IO.unlink } if $precomp-path.IO.e;
            
            # :INC patch reverted for now in rakudo
            # CompUnit.new($module.path, :INC(@paths) ).precomp;
            CompUnit.new($module.path).precomp;
            
            $precomp-path.IO.e 
                ?? @precompiled.push($precomp-path) && say "precomp ok" 
                !! "precomp not ok";
        }

        return @precompiled;
    }
}