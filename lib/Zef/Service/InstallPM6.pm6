use Zef;

class Zef::Service::InstallPM6 does Installer does Messenger {
    method install-matcher($dist) { $dist ~~ Distribution }

    method probe { True }

    method install($dist, :$cur, :$force) {
        $cur.install($dist, :$force);
    }
}
