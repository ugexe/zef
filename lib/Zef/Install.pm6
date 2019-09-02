use Zef;

class Zef::Install does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    method install-matcher($dist) { self.plugins.grep(*.install-matcher($dist)) }

    method install($candi, :$cur, :$force, Supplier :$logger, Int :$timeout) {
        my $dist      = $candi.dist;
        my $installer = self.install-matcher($dist).first(*.so);
        die "No installing backend available" unless ?$installer;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => INSTALL, phase => START, candi => $candi, message => "Installing with plugin: {$installer.^name}" });
            $installer.stdout.Supply.grep(*.defined).act: -> $out { $logger.emit({ level => VERBOSE, stage => INSTALL, phase => LIVE, candi => $candi, message => $out }) }
            $installer.stderr.Supply.grep(*.defined).act: -> $err { $logger.emit({ level => ERROR,   stage => INSTALL, phase => LIVE, candi => $candi, message => $err }) }
        }

        my $todo    = start { $installer.install($dist.compat, :$cur, :$force) };
        my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
        await Promise.anyof: $todo, $time-up;
        $logger.emit({ level => DEBUG, stage => INSTALL, phase => LIVE, candi => $candi, message => "Installing {$dist.path} timed out" })
            if ?$logger && $time-up.so && $todo.not;

        my $got = $todo.so ?? $todo.result !! False;

        return $got;
    }
}
