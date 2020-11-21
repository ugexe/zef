use Zef;
use Zef::Distribution;

# A 'Builder' that uses 1 or more other 'Builder' instances as backends. It abstracts the logic
# to do 'build this distribution with the first backend that supports the given distribution'.

class Zef::Build does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    # Returns true if any of the backends 'build-matcher' understand the given uri/path
    method build-matcher(Zef::Distribution $dist --> Bool:D) { return so self!build-matcher($dist) }

    # Returns the backends that understand the given uri based on their build-matcher result
    method !build-matcher(Zef::Distribution $dist --> Array[Builder]) {
        my @matching-backends = self.plugins.grep(*.build-matcher($dist));

        my Builder @results = @matching-backends;
        return @results;
    }

    # Build the given path using any provided @includes
    # Will return results from the first Builder backend that supports the given $candi.dist (distribution)
    method build(Candidate $candi, Str :@includes, Supplier :$logger, Int :$timeout, :$meta --> Array[Bool]) {
        my $dist := $candi.dist;
        die "Can't build non-existent path: {$dist.path}" unless $dist.path.IO.e;

        my $builder = self!build-matcher($dist).first(*.so);
        die "No building backend available" unless ?$builder;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => BUILD, phase => START, candi => $candi, message => "Building with plugin: {$builder.^name}" });
            $builder.stdout.Supply.grep(*.defined).act: -> $out { $logger.emit({ level => VERBOSE, stage => BUILD, phase => LIVE, candi => $candi, message => $out }) }
            $builder.stderr.Supply.grep(*.defined).act: -> $err { $logger.emit({ level => ERROR,   stage => BUILD, phase => LIVE, candi => $candi, message => $err }) }
        }

        my $todo    = start { try $builder.build($dist, :@includes) };
        my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
        await Promise.anyof: $todo, $time-up;
        $logger.emit({ level => DEBUG, stage => BUILD, phase => LIVE, candi => $candi, message => "Building {$dist.path} timed out" })
            if ?$logger && $time-up.so && $todo.not;

        my Bool @results = $todo.so ?? $todo.result !! False;
        return @results;
    }
}
