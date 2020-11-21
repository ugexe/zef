use Zef;

# An 'Tester' that uses 1 or more other 'Tester' instances as backends. It abstracts the logic
# to do 'test this path with the first backend that supports the given path'.

class Zef::Test does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    # Returns true if any of the backends 'test-matcher' understand the given uri/path
    method test-matcher($path --> Bool:D) { return so self!test-matcher($path) }

    # Returns the backends that understand the given uri based on their test-matcher result
    method !test-matcher($path --> Array[Tester]) {
        my @matching-backends = self.plugins.grep(*.test-matcher($path));

        my Tester @results = @matching-backends;
        return @results;
    }

    # Test the given path using any provided @includes
    # Will return results from the first Tester backend that supports the given path (via $candi.dist.path)
    # Note this differs from other 'Test' adapters .test() which takes a $uri or $path as the first
    # parameter, not a $candi.
    method test(Candidate $candi, Str :@includes, Supplier :$logger, Int :$timeout --> Array[Bool]) {
        my $path := $candi.dist.path;
        die "Can't test non-existent path: {$path}" unless $path.IO.e;

        my $testers := self!test-matcher($path).cache;

        unless +$testers {
            my @report_enabled  = self.plugins.map(*.short-name);
            my @report_disabled = self.backends.map(*.<short-name>).grep({ $_ ~~ none(@report_enabled) });

            die "Enabled testing backends [{@report_enabled}] don't understand $path\n"
            ~   "You may need to configure one of the following backends, or install its underlying software - [{@report_disabled}]";
        }

        my $tester = $testers.head;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => TEST, phase => START, candi => $candi, message => "Testing with plugin: {$tester.^name}" });
            $tester.stdout.Supply.grep(*.defined).act: -> $out is copy { $logger.emit({ level => VERBOSE, stage => TEST, phase => LIVE, candi => $candi, message => $out }) }
            $tester.stderr.Supply.grep(*.defined).act: -> $err is copy { $logger.emit({ level => ERROR,   stage => TEST, phase => LIVE, candi => $candi, message => $err }) }
        }

        my $todo    = start { try $tester.test($path, :@includes) };
        my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
        await Promise.anyof: $todo, $time-up;
        $logger.emit({ level => DEBUG, stage => TEST, phase => LIVE, message => "Testing $path timed out" })
            if ?$logger && $time-up.so && $todo.not;

        my Bool @results = $todo.so ?? $todo.result !! False;
        return @results;
    }
}
