use Zef::Phase::Getting;
use Zef::Plugin::Git;
use Zef::Utils::HTTPClient;

our $p6c = 'http://ecosystem-api.p6c.org/projects.json';

role Zef::Plugin::P6C does Zef::Phase::Getting {
    method get(:$save-to = $*TMPDIR, *@modules) {
        my $client   = Zef::Utils::HTTPClient.new;
        my $response = $client.get($p6c);
        my @dists = @(from-json($response.content));
        my @repos = @dists.grep({ $_.<name> ~~ any(@modules) }).grep({ $_.<source-url>:exists }).map({ $_.<source-url> });
        return Zef::Plugin::Git.new.get(:$save-to, @repos);
    }
}
