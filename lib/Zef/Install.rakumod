use Zef;
use Zef::Distribution;

class Zef::Install does Installer does Pluggable {

    =begin pod

    =title class Zef::Install

    =subtitle A configurable implementation of the Installer interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Install;
        use Zef::Distribution::Local;

        # Setup with a single installer backend
        my $installer = Zef::Install.new(
            backends => [
                { module  => "Zef::Service::InstallRakuDistribution" },
            ],
        );

        # Assuming our current directory is a raku distribution...
        my $dist-to-install = Zef::Distribution::Local.new($*CWD);
        my $candidate       = Candidate.new(dist => $dist-to-install);
        my $install-to-repo = CompUnit::RepositoryRegistry.repository-for-name("site");

        # ...install the distribution using the first available backend
        my $installed = so $installer.install($candidate, :cur($install-to-repo));
        say $installed ?? 'Install OK' !! 'Something went wrong...';

    =end code

    =head1 Description

    An C<Installer> class that uses 1 or more other C<Installer> instances as backends. It abstracts the logic
    to do 'install this distribution with the first backend that supports the given distribution'.

    =head1 Methods

    =head2 method install-matcher

        method install-matcher(Zef::Distribution $dist --> Bool:D)

    Returns C<True> if any of the probeable C<self.plugins> know how to install C<$dist>.

    =head2 method install

        method install(Candidate $candi, CompUnit::Repository :$cur!, Bool :$force, Supplier :$logger, Int :$timeout --> Bool:D)

    Installs the distribution C<$candi.dist> to C<$cur> (see synopsis). Set C<$force> to C<True> to allow installing a distribution
    that is already installed.

    An optional C<:$logger> can be supplied to receive events about what is occurring.

    An optional C<:$timeout> can be passed to denote the number of seconds after which we'll assume failure.

    Returns C<True> if the installation succeeded.

    Note In the future this might have backends allowing installation of e.g. Python modules for things using C<Inline::Python>.

    =end pod


    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    #| Returns true if any of the backends 'build-matcher' understand the given uri/path
    method install-matcher(Zef::Distribution $dist --> Bool:D) { return so self!install-matcher($dist) }

    #| Returns the backends that understand the given uri based on their build-matcher result
    method !install-matcher(Zef::Distribution $dist --> Array[Installer]) {
        my @matching-backends = self.plugins.grep(*.install-matcher($dist));

        my Installer @results = @matching-backends;
        return @results;
    }

    #| Install the distribution in $candi.dist to the $cur CompUnit::Repository.
    #| Use :force to install over an existing distribution using the same name/auth/ver/api
    method install(Candidate $candi, CompUnit::Repository :$cur!, Bool :$force, Supplier :$logger, Int :$timeout --> Bool:D) {
        my $dist      = $candi.dist;
        my $installer = self!install-matcher($dist).first(*.so);
        die "No installing backend available" unless ?$installer;

        my $stdout = Supplier.new;
        my $stderr = Supplier.new;
        if ?$logger {
            $logger.emit({ level => DEBUG, stage => INSTALL, phase => START, candi => $candi, message => "Installing with plugin: {$installer.^name}" });
            $stdout.Supply.grep(*.defined).act: -> $out { $logger.emit({ level => VERBOSE, stage => INSTALL, phase => LIVE, candi => $candi, message => $out }) }
            $stderr.Supply.grep(*.defined).act: -> $err { $logger.emit({ level => ERROR,   stage => INSTALL, phase => LIVE, candi => $candi, message => $err }) }
        }

        my $todo    = start { $installer.install($dist, :$cur, :$force, :$stdout, :$stderr) };
        my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
        await Promise.anyof: $todo, $time-up;
        $logger.emit({ level => DEBUG, stage => INSTALL, phase => LIVE, candi => $candi, message => "Installing {$dist.path} timed out" })
            if ?$logger && $time-up.so && $todo.not;

        my $got = $todo.so ?? $todo.result !! False;

        $stdout.done();
        $stderr.done();

        return $got;
    }
}
