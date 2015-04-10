use Zef::Phase::Building;
use Zef::Utils;
# todo: turn this into a panda compatability thing

role Zef::Plugin::PreComp does Zef::Phase::Building {
    multi method pre-compile(*@paths) {
        my @precompiled;

        my $supply = Supply.new;
        $supply.act(-> $path {
            my @files = Zef::Utils.comb($path);
            for @files {
                my $dest = "blib/{$_<file>.IO.relative}.{$*VM.precomp-ext}".IO.path;
                mkdir($dest.IO.dirname) or fail "couldnt mkdir" ;
                my $cmd  = "$*EXECUTABLE -Ilib --target={$*VM.precomp-target} --output='$dest' '{$_<file>}'";
                say $cmd;
                my $precomp = shell($cmd).exit == 0 ?? True  !! False;

                $dest.IO.e 
                    ?? @precompiled.push($*SPEC.catdir($*CWD,$dest)) && "precomp ok".say 
                    !! "precomp not ok".say;
            }
        });

        await @paths.map: { $supply.emit($*SPEC.catpath('', $_, 'lib')) };

        return @precompiled;
    }
}
