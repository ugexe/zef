use Zef;

class Zef::Test does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    method test-matcher($path) { self.plugins.grep(*.test-matcher($path)) }

    method test($candi, :@includes, Supplier :$logger, Int :$timeout) {
        my $path := $candi.dist.path;
        die "Can't test non-existent path: {$path}" unless $path.IO.e;

        my $testers := self.test-matcher($path).cache;

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

        my @got = $todo.so ?? $todo.result !! False;

        @got;
    }
}
