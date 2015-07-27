# A wrapper around Proc and Proc::Async
class Zef::Process {
    has $.id       is rw;
    has $.command  is rw;
    has @.args     is rw;
    has $.cwd      is rw;
    has $.stdout;
    has $.stderr;
    has $.stdmerge;
    has $.start-time;
    has $.end-time;
    has $.process;
    has $.promise;
    has $!type;
    has $.async;
    has $!can-async;
    has $.started;
    has $.finished;

    submethod BUILD(:$!command, :@!args, :$!cwd, Bool :$!async, :$!id) {
        $!can-async = !::("Proc::Async").isa(Failure);
        $!stdout = Supply.new;
        $!stderr = Supply.new;
        $!type   = $!async && $!can-async ?? ::("Proc::Async") !! ::("Proc");
        $!id     = $!id 
            ?? $!id 
            !! @!args 
                ?? @!args[*-1].item.IO.basename 
                !! $!command 
                    ?? $!command.IO.basename 
                    !! ''; # shameful

        die "Proc::Async not available, but option :\$!async explicitily requested it (JVM NYI)"
            if $!async && !$!can-async;
    }

    method start {
        # error check is duplicated here because, dun dun dunnn, JVM won't die otherwise
        die "Proc::Async not available, but option :\$!async explicitily requested it (JVM NYI)"
            if $!async && !$!can-async;

        if $!async {
            $!process = Proc::Async.new($*EXECUTABLE, @!args);
            $!process.stdout.act: { $!stdout.emit($_); $!stdmerge ~= $_ }
            $!process.stderr.act: { $!stderr.emit($_); $!stdmerge ~= $_ }

            my $cmd = "{$*EXECUTABLE} {@!args.join(' ')}";
            my $show-cmd = "{$*EXECUTABLE.basename} {@!args.join(' ')}";

            $!process.stdout.emit($show-cmd);

            $!started  := $!process.started;
            $!promise   = $!process.start(:$!cwd);
            $!finished := $!promise.Bool;

            $!promise;
        }
        else {
            my $cmd = "{$*EXECUTABLE} {@!args.join(' ')}";
            my $show-cmd = "{$*EXECUTABLE.basename} {@!args.join(' ')}";

            $!process = shell("$cmd 2>&1", :out, :$!cwd, :!chomp);

            $!promise = Promise.new;
            $!stdout.act: { $!stdmerge ~= $_ }
            $!stderr.act: { $!stdmerge ~= $_ }

            $!stdout.emit($show-cmd);

            $!started = True;
            $!stdout.emit($_) for $!process.out.lines;
            $!finished = ?$!promise.keep($!process.status);

            $!process.out.close; 
        }

        $!promise;
    }

    method status { $!process.status }
    method ok     { 
        return unless $!process.DEFINITE;

        if $!promise.^find_method('result').DEFINITE 
            && $!promise.result.^find_method('exitcode').DEFINITE {
            return $!promise.result.exitcode == 0 ?? True !! False 
        }
        else {
            return $!process.exitcode == 0 ?? True !! False 
        }
    }
    method nok { ?$.ok() ?? False !! True }
}