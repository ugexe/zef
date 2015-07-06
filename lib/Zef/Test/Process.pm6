# Zef::Test::Process represents a single test file and the results of running it.
# Pass an unstarted Proc::Async object. $file can likely be removed as a constructor 
# and parsed from $process.args or $process.stdout.
# 
# method status
# Get the exit code of the process that ran the tests.
#
# method ok
# Convenience method. Returns `True` if the exit code was 0 (success). Otherwise, `False`.

class Zef::Test::Process {
    has $.file     is rw;
    has $.cwd      is rw;
    has @.includes is rw;
    has $.stdout;
    has $.stderr;
    has $.stdmerged;
    has $.start-time;
    has $.end-time;
    has $.process;
    has $.promise;

    has $.started;
    has $.finished;

    submethod BUILD(:$!file, :$!cwd, :@!includes) {
        $!stdout = Supply.new;
        $!stderr = Supply.new;        
    }

    method start {
        # Example of @!includes usage:
        # @!includes = "lib", "blib/lib", "/tmp/Dependency/blib";
        # --> -Ilib -Iblib/lib -I/tmp/Dependency/blib
        my @includes-as-args = @!includes.map({ qqw/-I$_/ });
        my $test-path = ?$!file.IO.is-relative ?? $!file.IO.relative !! $*SPEC.abs2rel($!file, $!cwd);

        $!process = Proc::Async.new($*EXECUTABLE, @includes-as-args, $test-path);
        
        $!process.stdout.act: { $!stdout.emit($_); $!stdmerged ~= $_ };
        $!process.stderr.act: { $!stderr.emit($_); $!stdmerged ~= $_ };

        $!started  := $!process.started;
        $!promise   = $!process.start(:$!cwd);
        $!finished := $!promise.Bool;

        $!promise;
    }

    method status { $!promise.result.status }
    method ok     { $!promise.result.exitcode == 0 ?? True !! False }
}