use Zef::Phase::Getting;
use LWP::Simple;

# use to fetch .tar.tz from github
# todo: add role to un-tar/zip files to complete other half of 'fetcher'

role Zef::Plugin::LWP does Zef::Phase::Getting {
    has $.lwp = LWP::Simple.new;

    multi method get($url, $save_to) {
        $.lwp.getstore($url, $save_to.Str);
    }
}
