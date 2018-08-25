use Zef;

class Zef::Test does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    method test-matcher($path) { self.plugins.grep(*.test-matcher($path)) }

    method test($path, :@includes, Supplier :$logger, Int :$timeout) {
        die "Can't test non-existent path: {$path}" unless $path.IO.e;
        my $testers := self.test-matcher($path).cache;

        unless +$testers {
            my @report_enabled  = self.plugins.map(*.short-name);
            my @report_disabled = self.backends.map(*.<short-name>).grep({ $_ ~~ none(@report_enabled) });

            die "Enabled testing backends [{@report_enabled}] don't understand $path\n"
            ~   "You may need to configure one of the following backends, or install its underlying software - [{@report_disabled}]";
        }

        my $tester = $testers.head;

        my $stdmerge;
        my sub save-test-output($str) {
            state $lock = Lock.new;
            $lock.protect({ $stdmerge ~= $str });
        }
        if ?$logger {
            $logger.emit({ level => DEBUG, stage => TEST, phase => START, message => "Testing with plugin: {$tester.^name}" });
            $tester.stdout.Supply.grep(*.defined).act: -> $out { save-test-output($out); $logger.emit({ level => VERBOSE, stage => TEST, phase => LIVE, message => $out }) }
            $tester.stderr.Supply.grep(*.defined).act: -> $err { save-test-output($err); $logger.emit({ level => ERROR,   stage => TEST, phase => LIVE, message => $err }) }
        }

        my $todo    = start { try $tester.test($path, :@includes) };
        my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
        await Promise.anyof: $todo, $time-up;
        $logger.emit({ level => DEBUG, stage => FETCH, phase => LIVE, message => "Testing $path timed out" })
            if $time-up.so && $todo.not;

        my @got = $todo.so ?? $todo.result !! False;

        $tester.stdout.done;
        $tester.stderr.done;

        @got does role :: { method Str { $stdmerge } };

        @got;
    }
}
