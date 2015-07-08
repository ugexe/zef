# this will be meant to be a non-blocking compatability wrapper for Proc and Proc::Async
class Zef::Test::Process {
    has $.file     is rw;
    has $.cwd      is rw;
    has @.includes is rw;
    has $.stdout;
    has $.stderr;
    has $.stdmerge;
    has $.start-time;
    has $.end-time;
    has $.process;
    has $.promise;
    has $!proc;
    has $.async;
    has $!can-async;
    has $.started;
    has $.finished;

    submethod BUILD(:$!file, :$!cwd, :@!includes, Bool :$!async) {
        $!can-async = !::("Proc::Async").isa(Failure);
        $!stdout = Supply.new;
        $!stderr = Supply.new;
        $!proc   = $!async && $!can-async ?? ::("Proc::Async") !! ::("Proc");

         die "Proc::Async not available, but option :\$!async explicitily requested it (JVM NYI)"
            if $!async && !$!can-async;
    }

    method start {
        # error check is duplicated here because, dun dun dunnn, JVM won't die otherwise
        die "Proc::Async not available, but option :\$!async explicitily requested it (JVM NYI)"
            if $!async && !$!can-async;

        my @includes-as-args = @!includes.map({ qqw/-I$_/ });
        my $test-path = ?$!file.IO.is-relative ?? $!file.IO.relative !! $*SPEC.abs2rel($!file, $!cwd);

        if $!async {
            $!process = Proc::Async.new($*EXECUTABLE, @includes-as-args, $test-path);
            
            $!process.stdout.act: { $!stdout.emit($_); $!stdmerge ~= $_ }
            $!process.stderr.act: { $!stderr.emit($_); $!stdmerge ~= $_ }

            $!started  := $!process.started;
            $!promise   = $!process.start(:$!cwd);
            $!finished := $!promise.Bool;

            $!promise;
        }
        else {
            # No Proc::Async on JVM yet, so we will make do with this Proc wrapper
            my $cmd = "{$*EXECUTABLE} {@includes-as-args.join(' ')} $test-path";
            $!process = shell("$cmd 2>&1", :out, :$!cwd, :!chomp);

            $!promise = Promise.new; #start({
                $!stdout.act: { $!stdmerge ~= $_ }
                $!started = True;
                $!stdout.emit($_) for $!process.out.lines;
                $!finished = ?$!promise.keep($!process.status);
            #}).then({ 
                $!stdout.close; $!stderr.close; $!process.out.close; 
            #});
        }

        $!promise;
    }

    method status { $!process.status }
    method ok     { 
        if $!promise.^find_method('result').DEFINITE 
            && $!promise.result.^find_method('exitcode').DEFINITE {
            return $!promise.result.exitcode == 0 ?? True !! False 
        }
        else {
            return $!process.exitcode == 0 ?? True !! False 
        }
    }
}