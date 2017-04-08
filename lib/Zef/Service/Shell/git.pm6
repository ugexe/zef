use Zef;
use Zef::Shell;
use Zef::Utils::URI;

# todo: have a similar interface for git fetch/extract via `run` but using --archive

my role GitFetcher {
    has $.scheme;

    # FETCH (clone/pull) INTERFACE
    method fetch-matcher($url) {
        if uri($url) -> $uri {
            return True if $uri.scheme.lc eq 'git';
            return True if $uri.scheme.lc.starts-with('http' | 'ssh') && $uri.path.ends-with('.git' || '.git/');
        }
        False;
    }

    multi method fetch($orig-url, $save-as) {
        # allow overriding the default scheme of git urls
        my $url = $!scheme ?? $orig-url.subst(/^\w+ '://'/, "{$!scheme}://") !! $orig-url;

        my $clone-proc := $.zrun('git', 'clone', $url, $save-as.IO.absolute, '--quiet', :cwd($save-as.IO.parent));
        my $pull-proc  := $.zrun('git', 'pull', '--quiet', :cwd($save-as.IO.absolute));

        return ?$clone-proc || ?$pull-proc ?? $save-as !! False;
    }
}

my role GitExtractor {
    # EXTRACT (checkout) interface
    method extract-matcher($str) {
        my ($path, $checkout) = $str.match(/^(.+?)['#' (.*)]?$/);
        return False unless $path.IO.d;
        ?$.zrun('git', 'status', :cwd($path));
    }

    method extract($path, $work-tree) {
        my ($repo, $checkout) = $path.match(/^(.+?)['#' (.*)]?$/)>>.Str || return False;
        $checkout = $checkout.?chars ?? $checkout !! 'HEAD';
        return False unless $repo.IO.d && $repo.IO.child('.git').d;

        die "repo directory does not exist: {$repo}"
            unless $repo.IO.e && $repo.IO.d;
        die "\{$work-tree} folder does not exist and could not be created"
            unless ($work-tree.IO.d || mkdir($work-tree));

        my $sha-proc = $.zrun('git', 'rev-parse', $checkout, :cwd($repo), :out, :err);
        my @out      = $sha-proc.out.lines;
        my @err      = $sha-proc.out.lines;
        $sha-proc.out.close;
        $sha-proc.err.close;

        my $sha      = @out[0];
        my $sha-dir  = $work-tree.IO.child($sha);
        die "Failed to checkout to directory: {$sha-dir}"
            unless ($sha-dir.IO.d || mkdir($sha-dir));

        my $co-proc  = $.zrun('git', '--work-tree', $sha-dir, 'checkout', $sha, '.', :cwd($repo));
        ?(?$sha-proc && ?$co-proc) ?? $sha-dir.absolute !! False;
    }

    method list($repo) {
        my $proc = $.zrun('git', 'ls-files', :cwd($repo), :out);
        my @extracted-paths = $proc.out.lines;
        $proc.out.close;
        @ = ?$proc ?? @extracted-paths.grep(*.defined) !! ();
    }
}

class Zef::Service::Shell::git is Zef::Shell does Probeable does Messenger {
    also does GitFetcher;
    also does GitExtractor;

    method probe {
        state $git-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            so zrun('git', '--help');
        }
        ?$git-probe;
    }
}
