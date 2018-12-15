use Zef;

class Zef::Install does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    method install-matcher($dist) { self.plugins.grep(*.install-matcher($dist)) }

    method install($dist, :$cur, :$force, Supplier :$logger, Int :$timeout) {
        my $installer = self.install-matcher($dist).first(*.so);
        die "No installing backend available" unless ?$installer;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => INSTALL, phase => START, message => "Installing with plugin: {$installer.^name}" });
            $installer.stdout.Supply.grep(*.defined).act: -> $out { $logger.emit({ level => VERBOSE, stage => INSTALL, phase => LIVE, message => $out }) }
            $installer.stderr.Supply.grep(*.defined).act: -> $err { $logger.emit({ level => ERROR,   stage => INSTALL, phase => LIVE, message => $err }) }
        }

        my $todo    = start { $installer.install($dist, :$cur, :$force) };
        my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
        await Promise.anyof: $todo, $time-up;
        $logger.emit({ level => DEBUG, stage => INSTALL, phase => LIVE, message => "Installing {$dist.path} timed out" })
            if $time-up.so && $todo.not;

        my $got = $todo.so ?? $todo.result !! False;

        $installer.stdout.done;
        $installer.stderr.done;

        return $got;
    }
}
