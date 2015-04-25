use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::FileSystem;
# todo: turn this into a panda compatability thing

role Zef::Plugin::PreComp does Zef::Phase::Building {
    multi method pre-compile(*@paths) {
        my @precompiled;
        my @libs     = @paths.map({$*SPEC.catpath('', $_, 'lib')});
        my @deps     = @libs.map({ Zef::Utils::FileSystem.extract-deps($_) });
        my @dep-tree = Zef::Utils::Depends.build(@deps);

        for @dep-tree {
            my $dest = "blib/{$_<file>.IO.relative}.{$*VM.precomp-ext}".IO.path;
            mkdir($dest.IO.dirname) or fail "couldnt mkdir" ;
            my $cmd  = "$*EXECUTABLE -Ilib --target={$*VM.precomp-target} --output='$dest' '{$_<file>}'";
            say $cmd;
            my $precomp = shell($cmd).exitcode == 0 ?? True  !! False;

            $dest.IO.e 
                ?? @precompiled.push($*SPEC.catdir($*CWD,$dest)) && "precomp ok".say 
                !! "precomp not ok".say;
        }

        return @precompiled;
    }
}
