use Zef::Phase::Building;
use Zef::Utils::Depends;
use Zef::Utils::PathTools;
# todo: turn this into a panda compatability thing

role Zef::Plugin::PreComp does Zef::Phase::Building {
    method pre-compile(*@paths) {
        for @paths -> $path {
            my @precompiled;
            my @libs = $path.IO.ls(:r, :f);
            my @deps = Zef::Utils::Depends.build-dep-tree: extract-deps(@libs);

            for @deps -> %dep {
                my $blib-lib = $*SPEC.catdir("blib", %dep<file>.IO.dirname.IO.relative).IO;
                my $dest     = $*SPEC.catpath('', $blib-lib.IO.path, "{%dep<file>.IO.basename}.{$*VM.precomp-ext}").IO;
                try mkdirs($blib-lib);
                try rm(%dep<file>.IO);

                say my $cmd  = "$*EXECUTABLE -Iblib/lib --target={$*VM.precomp-target} --output='$dest' '{%dep<file>.IO.relative}'";
                my $precomp  = shell($cmd).exitcode == 0 ?? True  !! False;

                $dest.IO.e 
                    ?? @precompiled.push($dest.IO.path) && "precomp ok".say 
                    !! "precomp not ok".say;
            }

            return @precompiled;
        }
    }
}
