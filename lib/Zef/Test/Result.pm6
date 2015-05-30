class Zef::Test::Result {
    has $.process;
    has $.promise;
    has $.file;
    has $.stdout     is rw;
    has $.stderr     is rw;
    has $.start-time is rw;
    has $.end-time   is rw;

    submethod BUILD(:$!process, :$!file) {
        LEAVE $!promise = $!process.start;
        $!process.stdout.tap: -> $o { $!stdout ~= $o }
        $!process.stderr.tap: -> $o { $!stderr ~= $o }
    }
    method status { $!promise.result.exitcode }
    method ok     { ?$!promise.result.exitcode ?? False !! True }
}