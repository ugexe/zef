# Zef::Test::Result represents a single test file and the results of running it.
# Pass an unstarted Proc::Async object. $file can likely be removed as a constructor 
# and parsed from $process.args or $process.stdout.
# 
# method status
# Get the exit code of the process that ran the tests.
#
# method ok
# Convenience method. Returns `True` if the exit code was 0 (success). Otherwise, `False`.

class Zef::Test::Result {
    has $.process;
    has $.promise;
    has $.file;
    has $.path;
    has Supply $.stdout;
    has Supply $.stderr;
    has $.start-time is rw;
    has $.end-time   is rw;
    has $.output     is rw;

    # Starts the test as soon as object is initiated. This may change.
    submethod BUILD(:$!process, :$!file, :$!path) {
        LEAVE $!promise := $!process.start;
        $!stdout := $!process.stdout;
        $!stderr := $!process.stderr;

        $!process.stdout.act: { $!output ~= $_ };
        $!process.stderr.act: { $!output ~= $_ };
    }

    method status { $!promise.result.exitcode }
    method ok     { ?$!promise.result.exitcode ?? False !! True }
}