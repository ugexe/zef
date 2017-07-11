use Zef;
use Zef::Utils::URI;

# todo: have a similar interface for git fetch/extract via `run` but using --archive

my role GitFetcher {
    has $.scheme;

    # FETCH (clone/pull) INTERFACE
    method fetch-matcher($url) {
        if uri($url) -> $uri {
            return True if $uri.scheme.lc eq 'git';
            return True if $uri.scheme.lc.starts-with('http' | 'ssh') && $uri.path.ends-with('.git' | '.git/');
        }
        False;
    }

    multi method fetch($orig-url, $save-as) {
        # allow overriding the default scheme of git urls
        my $url = $!scheme ?? $orig-url.subst(/^\w+ '://'/, "{$!scheme}://") !! $orig-url;

        my $clone-proc := zrun('git', 'clone', $url, $save-as.IO.absolute, '--quiet', :!out, :!err, :cwd($save-as.IO.parent));
        my $pull-proc  := zrun('git', 'pull', '--quiet', :!out, :!err, :cwd($save-as.IO.absolute));

        return ($clone-proc.so || $pull-proc.so) ?? $save-as !! False;
    }
}

my role GitExtractor {
    # EXTRACT (checkout) interface
    method extract-matcher($str) {
        my ($repo, $checkout) = $str.match(/^(.+?)['#' (.*)]?$/);
        return False unless $repo.IO.d;
        my $proc = zrun('git', 'status', :!out, :!err, :cwd($repo));
        $proc.so ?? True !! False;
    }

    method extract($path, $work-tree) {
        my ($repo, $checkout) = $path.match(/^(.+?)['#' (.*)]?$/)>>.Str || return False;
        $checkout = $checkout.?chars ?? $checkout !! 'HEAD';
        return False unless $repo.IO.d && $repo.IO.child('.git').d;

        die "repo directory does not exist: {$repo}"
            unless $repo.IO.e && $repo.IO.d;
        die "\{$work-tree} folder does not exist and could not be created"
            unless ($work-tree.IO.d || mkdir($work-tree));

        my $sha-proc = zrun('git', 'rev-parse', $checkout, :cwd($repo), :out, :!err);
        my @out      = $sha-proc.out.lines;
        $sha-proc.out.close;

        my $sha      = @out[0];
        my $sha-dir  = $work-tree.IO.child($sha);
        die "Failed to checkout to directory: {$sha-dir}"
            unless ($sha-dir.IO.d || mkdir($sha-dir));

        my $co-proc  = zrun('git', '--work-tree', $sha-dir, 'checkout', $sha, '.', :cwd($repo), :!out, :!err);

        ($sha-proc.so && $co-proc.so) ?? $sha-dir.absolute !! False;
    }

    method list($repo) {
        my $proc = zrun('git', 'ls-files', :cwd($repo), :out, :!err);
        my @extracted-paths = $proc.out.lines;
        $proc.out.close;
        $proc.so ?? @extracted-paths.grep(*.defined) !! ();
    }
}

class Zef::Service::Shell::git does Probeable does Messenger {
    also does GitFetcher;
    also does GitExtractor;

    method probe {
        state $probe = try { run('git', '--help', :!out, :!err).so };
    }
}
