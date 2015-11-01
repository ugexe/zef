# example of dependency-free Build.pm file that any installer can use but still works with panda
class Build {
    method build($workdir) {
        say "\n[LEGACY HOOK `Build.pm`: {$*PROGRAM.basename}] launched OK";
    }

    method isa($what) { return True if $what.^name eq 'Panda::Builder'; callsame }
}
