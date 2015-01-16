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
            say "";
            say "---DEBUG precomp---";
            my $cu = CompUnit.new($module.path, :INC(@dirs) );

            # Not exactly happy with this current solution. If something 
            # should fail before everything is precompiled we would be 
            # left with precompiled modules from 2 different versions.
            # Sure, there are bigger problems if something fails in the middle, 
            # but it would still be ideal to first delete all the precompiled 
            # copies of a module's sub modules. As this requires a (current 
            # unimplemented) dependency tree builder, we won't bother to 
            # just delete them here as encountered as it will lead to 
            # the same problem. (i.e. we want to delete all precompiled
            # versions before we build any specific module of the repo)
            $cu.precomp(:force);

            # if $cu.has-precomp { # has-precomp will return True if you
                                   # delete a previously existing precompiled
                                   # file after the CompUnit.new above
            if $cu.precomp-path.IO.e { # so just check for the file's existence
                @precompiled.push($cu.precomp-path);
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