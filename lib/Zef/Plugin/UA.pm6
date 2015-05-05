use Zef::Phase::Getting;

# use to fetch .tar.tz from github
# todo: add role to un-tar/zip files to complete other half of 'fetcher'

role Zef::Plugin::UA does Zef::Phase::Getting {
    has $!ua = ENTER {
        try {
            require HTTP::UserAgent;
            HTTP::UserAgent.new(useragent => 'firefox_linux');
        }
        X::NYI::Available.new(:available("HTTP::UserAgent"), :feature("http::useragent and openssl")).message.say;            
    }

    method get(:$save-to = $*TMPDIR, *@urls) {
        my @fetched;
        my @failed;

        for @urls -> $url {
            KEEP @fetched.push($url);
            UNDO @failed.push($url);

            my $response = $.ua.get($url);

            if $response.is-success {
                $save-to.IO.open(:bin, :w).write($response.content);
            }
            else {
                fail $response.status-line;
            }
        }

        return %(@fetched.map({ $_ => True }), @failed.map({ $_ => False }));
    }
}
