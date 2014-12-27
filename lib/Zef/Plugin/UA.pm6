use Zef::Phase::Getting;
use HTTP::UserAgent;
require IO::Socket::SSL; 

# use to fetch .tar.tz from github
# todo: add role to un-tar/zip files to complete other half of 'fetcher'

role Zef::Plugin::UA does Zef::Phase::Getting {
    has $.ua = HTTP::UserAgent.new(useragent => 'firefox_linux');

    multi method get($url, $file) {
        my $response = $.ua.get($url);

        if $response.is-success {
            $file.IO.open(:bin, :w).write($response.content);
        }
        else {
            fail $response.status-line;
        }
    }
}
