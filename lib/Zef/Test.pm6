use Zef;

class Zef::Test does Pluggable {
    method test($path, :@includes, Supplier :$logger) {
        die "Can't test non-existent path: {$path}" unless $path.IO.e;
        my $tester = self.plugins.first(*.test-matcher($path));
        die "No testing backend available" unless ?$tester;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => TEST, phase => START, payload => self, message => "Testing with plugin: {$tester.^name}" });
            $tester.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => TEST, phase => LIVE, message => $out }) }
            $tester.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => TEST, phase => LIVE, message => $err }) }
        }

        my @got = try $tester.test($path, :@includes);

        $tester.stdout.done;
        $tester.stderr.done;

        @got;
    }
}
