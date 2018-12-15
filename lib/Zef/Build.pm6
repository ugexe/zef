use Zef;

class Zef::Build does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    method build-matcher($dist) { self.plugins.grep(*.build-matcher($dist)) }

    method build($dist, :@includes, Supplier :$logger, Int :$timeout, :$meta) {
        die "Can't build non-existent path: {$dist.path}" unless $dist.path.IO.e;
        my $builder = self.build-matcher($dist).first(*.so);
        die "No building backend available" unless ?$builder;

        my $stdmerge;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => BUILD, phase => START, message => "Building with plugin: {$builder.^name}" });
            $builder.stdout.Supply.grep(*.defined).act: -> $out { $stdmerge ~= $out; $logger.emit({ level => VERBOSE, stage => BUILD, phase => LIVE, message => $out }) }
            $builder.stderr.Supply.grep(*.defined).act: -> $err { $stdmerge ~= $err; $logger.emit({ level => ERROR,   stage => BUILD, phase => LIVE, message => $err }) }
        }

        my $todo    = start { try $builder.build($dist, :@includes) };
        my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
        await Promise.anyof: $todo, $time-up;
        $logger.emit({ level => DEBUG, stage => BUILD, phase => LIVE, message => "Building {$dist.path} timed out" })
            if $time-up.so && $todo.not;

        my @got = $todo.so ?? $todo.result !! False;

        $builder.stdout.done;
        $builder.stderr.done;

        @got does role :: { method Str { $stdmerge } }; # boolify for pass/fail, stringify for report

        @got;
    }
}
