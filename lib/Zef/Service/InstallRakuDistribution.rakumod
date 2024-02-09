use Zef:ver($?DISTRIBUTION.meta<version> // $?DISTRIBUTION.meta<ver>// '*'):api($?DISTRIBUTION.meta<api> // '*'):auth($?DISTRIBUTION.meta<auth> // '');

class Zef::Service::InstallRakuDistribution does Installer {

    =begin pod

    =title class Zef::Service::InstallRakuDistribution

    =subtitle A raku CompUnit::Repository based implementation of the Installer interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::InstallRakuDistribution;

        my $installer = Zef::Service::InstallRakuDistribution.new;

        # Add logging if we want to see output
        my $stdout = Supplier.new;
        my $stderr = Supplier.new;
        $stdout.Supply.tap: { say $_ };
        $stderr.Supply.tap: { note $_ };

        # Assuming our current directory is a raku distribution
        # with no dependencies or all dependencies already installed...
        my $dist-to-install = Zef::Distribution::Local.new($*CWD);
        my $cur = CompUnit::RepositoryRegistry.repository-for-name("site"); # default install location
        my $passed = so $installer.install($dist-to-test, :$cur, :$stdout, :$stderr);
        say $passed ?? "PASS" !! "FAIL";

    =end code

    =head1 Description

    C<Installer> class for handling raku C<Distribution> installation (it installs raku modules).

    You probably never want to use this unless its indirectly through C<Zef::Install>.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module believes all run time prerequisites are met. Since the only prerequisite
    is C<$*EXECUTABLE> this always returns C<True>.

    =head2 method install-matcher

        method install-matcher(Distribution $ --> Bool:D) { return True }

    Returns C<True> if this module knows how to install the given C<Distribution>.

    Note: This always returns C<True> right now, but may not in the future if zef learns how to
    install packages from other languages (such as perl via a cpanm wrapper).

    =head2 method install
    
        method install(Distribution $dist, CompUnit::Repository :$cur, Bool :$force, Bool :$precompile, Supplier $stdout, Suppluer :$stderr --> Bool:D)

    Install the distribution C<$dist> to the CompUnit::Repository C<$cur>. If C<$force> is C<True>
    then it will allow reinstalling an already installed distribution. If C<$precompile> is C<False>
    then it will not precompile during installation. A C<Supplier> can be supplied as C<:$stdout>
    and C<:$stderr> to receive any output.

    Returns C<True> if the install succeeded.

    =end pod


    #| Always return True since this is using the built-in raku installation logic
    method probe(--> Bool:D) { True }

    #| Return true as long as we have a Distribution class that raku knows how to install
    method install-matcher(Distribution $ --> Bool:D) { return True }

    #| Install the distribution in $candi.dist to the $cur CompUnit::Repository.
    #| Use :force to install over an existing distribution using the same name/auth/ver/api
    method install(Distribution $dist, CompUnit::Repository :$cur, Bool :$force, Bool :$precompile, Supplier :$stdout, Supplier :$stderr --> Bool:D) {
        $cur.install($dist, :$precompile, :$force);
        return True;
    }
}
