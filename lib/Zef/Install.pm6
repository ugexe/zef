use Zef;
use Zef::Distribution;

# A 'Installer' that uses 1 or more other 'Installer' instances as backends. It abstracts the logic
# to do 'install this distribution with the first backend that supports the given distribution'.

class Zef::Install does Pluggable {
    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    # Returns true if any of the backends 'build-matcher' understand the given uri/path
    method install-matcher(Zef::Distribution $dist --> Bool:D) { return so self!install-matcher($dist) }

    # Returns the backends that understand the given uri based on their build-matcher result
    method !install-matcher(Zef::Distribution $dist --> Array[Installer]) {
        my @matching-backends = self.plugins.grep(*.install-matcher($dist));

        my Installer @results = @matching-backends;
        return @results;
    }

    # Install the distribution in $candi.dist to the $cur CompUnit::Repository.
    # Use --force to install over an existing distribution using the same name/auth/ver/api
    method install(Candidate $candi, CompUnit::Repository :$cur, Bool :$force, Supplier :$logger, Int :$timeout --> Bool:D) {
        my $dist      = $candi.dist;
        my $installer = self!install-matcher($dist).first(*.so);
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
