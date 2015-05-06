use Zef::Phase::Getting;

# use to fetch .tar.tz from github
# todo: add role to un-tar/zip files to complete other half of 'fetcher'

role Zef::Plugin::UA does Zef::Phase::Getting {
    ENTER { 
        try require HTTP::UserAgent;
        if ::('HTTP::UserAgent') ~~ Failure {
            X::NYI::Available.new(:available("HTTP::UserAgent"), :feature("Zef::Plugin::UA")).message.say;            
        }
    }

    method get(:$save-to-file = $*TMPDIR, *@urls) {
        my @results = eager gather for @urls -> $url {
            my $response = ::('HTTP::UserAgent').new.get($url);

            if $response.is-success {
                $save-to-file.IO.spurt($response.content);
                take { ok => 1, path => $save-to-file }
            }
            else {
                take { ok => 0, path => $save-to-file }
                fail $response.status-line;
            }
        }

        return @results;
    }
}
