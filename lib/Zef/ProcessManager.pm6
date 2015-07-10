use Zef::Process;

# Manage multiple Proc/Proc::Async objects
class Zef::ProcessManager {
    has @.processes;
    has $.promise;
    has $.async;
    has $.cwd;

    submethod BUILD(Bool :$!async, :$!cwd = $*CWD) { }

    method create($file, *@args, :$cwd = $!cwd, :$id) {
        my $proc = Zef::Process.new(:$file, :@args, :$!async, :$cwd, :$id);
        @!processes.push: $proc;
        return $proc;
    }

    method start-all(:$p6flags) {
        if @!processes {
            @!processes>>.start;
            $!promise = Promise.allof( @!processes>>.promise );
        }
        else {
            $!promise = Promise.new;
            $!promise.keep(1);
        }

        $!promise;
    }

    method tap-all(&code) {
        @!processes>>.tap(&code);
    }

    method ok-all {
        ?all(@!processes>>.ok);
    }

    method kill-all { }
}
