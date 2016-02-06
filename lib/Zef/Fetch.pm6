use Zef;
use Zef::Utils::URI;

class Zef::Fetch does Pluggable {
    method ACCEPTS($uri) { $ = $uri ~~ @$.plugins }

    method fetch($uri, $save-as, :&stdout = -> $o {$o.say}, :&stderr = -> $e {$e.say}) {
        # .zef/tmp/zef
        #my $dist-repo = $save-as.IO.child(Zef::Utils::URI($uri).path.IO.basename);
        #mkdir($dist-repo) unless $dist-repo.e;
        # .zef/tmp/zef/{time stamp}
        #my $dist-path = $dist-repo.child(time);
        #mkdir($dist-path) unless $dist-path.e;
        my $fetchers = self.plugins.grep(*.fetch-matcher($uri));

        die "No fetching backend available" unless ?$fetchers;

        $fetchers[0].stdout.Supply.act(&stdout);
        $fetchers[0].stderr.Supply.act(&stderr);

        my $got = $fetchers[0].fetch($uri, $save-as);

        $fetchers[0].stdout.done;
        $fetchers[0].stderr.done;

        return $got;
    }
}
