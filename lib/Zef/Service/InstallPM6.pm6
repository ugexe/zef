use Zef;

class Zef::Service::InstallPM6 does Installer does Messenger {

    =begin pod

    =title class Zef::Service::InstallPM6

    =subtitle A raku CompUnit::Repository based implementation of the Installer interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::InstallPM6;

        my $installer = Zef::Service::InstallPM6.new;

        # Assuming our current directory is a raku distribution
        # with no dependencies or all dependencies already installed...
        my $dist-to-install = Zef::Distribution::Local.new($*CWD);
        my $cur = CompUnit::RepositoryRegistry.repository-for-name("site"); # default install location
        my $passed = so $installer.install($dist-to-test, :$cur);
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

        method install-matcher(Distribution $dist --> Bool:D) { return True }

    Returns C<True> if this module knows how to install the distribution C<$dist>.

    Note: This always returns C<True> right now, but may not in the future if zef learns how to
    install packages from other languages (such as perl via a cpanm wrapper).

    =head2 method install
    
        method install(Distribution $dist, CompUnit::Repository :$cur, Bool :$force --> Bool:D)

    Install the distribution C<$dist> to the CompUnit::Repository C<$cur>. If C<$force> is C<True>
    then it will allow reinstalling an already installed distribution.

    Returns C<True> if the install succeeded.

    =end pod


    #| Always return True since this is using the built-in raku installation logic
    method probe(--> Bool:D) { True }

    #| Return true as long as we have a Distribution class that raku knows how to install
    method install-matcher(Distribution $dist --> Bool:D) { return True }

    #| Install the distribution in $candi.dist to the $cur CompUnit::Repository.
    #| Use :force to install over an existing distribution using the same name/auth/ver/api
    method install(Distribution $dist, CompUnit::Repository :$cur, Bool :$force --> Bool:D) {
        $cur.install($dist, :$force);
        return True;
    }
}
