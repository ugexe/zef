use Zef;

class Zef::Test does Pluggable {
    method test($path, :@includes, Supplier :$logger) {
        die "Can't test non-existent path: {$path}" unless $path.IO.e;
        my $testers := self.plugins.grep(*.test-matcher($path)).cache;

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

        my @got = try $tester.test($path, :@includes);

        $tester.stdout.done;
        $tester.stderr.done;

        @got does role :: { method Str { $stdmerge } };

        @got;
    }
}
