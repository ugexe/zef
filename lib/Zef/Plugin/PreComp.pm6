use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::FileSystem;
# todo: turn this into a panda compatability thing

role Zef::Plugin::PreComp does Zef::Phase::Building {
    method pre-compile(*@paths) {
        my @precompiled;
        my @deps     = @paths.map({ extract-deps($*SPEC.catdir($_, 'lib')) });
        my @dep-tree = Zef::Utils::Depends.build(@deps);

        for @dep-tree -> %dep {
            my $blib-lib = $*SPEC.catdir("blib", %dep<file>.IO.dirname.IO.relative).IO;
            my $dest     = $*SPEC.catpath('', $blib-lib.IO.path, "{%dep<file>.IO.basename}.{$*VM.precomp-ext}").IO;
            try mkdirs($blib-lib.IO.path);
            try rm(%dep<file>.IO.path);

            say my $cmd  = "$*EXECUTABLE -Iblib/lib --target={$*VM.precomp-target} --output='$dest' '{%dep<file>.IO.relative}'";
            my $precomp = shell($cmd).exitcode == 0 ?? True  !! False;

            $dest.IO.e 
                ?? @precompiled.push($dest.IO.path) && "precomp ok".say 
                !! "precomp not ok".say;
        }

        return @precompiled;
    }
}
