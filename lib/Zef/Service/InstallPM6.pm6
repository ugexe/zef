use Zef;

class Zef::Service::InstallPM6 does Installer does Messenger {
    # Return true as long as we have a Distribution class that raku knows how to install
    method install-matcher(Distribution $dist) { return True }

    # Always return True since this is using the built-in raku installation logic
    method probe(--> Bool:D) { True }

    # Install the distribution in $candi.dist to the $cur CompUnit::Repository.
    # Use --force to install over an existing distribution using the same name/auth/ver/api
    method install(Distribution $dist, CompUnit::Repository :$cur, Bool :$force --> Bool:D) {
        $cur.install($dist, :$force);
        return True;
    }
}
