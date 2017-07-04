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

        if !$save-as.IO.e || !$save-as.IO.dir.elems {
            my $clone-proc = run('git', 'clone', $url, $save-as.IO.absolute, :cwd($save-as.IO.parent));
            return $save-as if $clone-proc.exitcode == 0;
        }

        if $save-as.IO.e {
            my $pull-proc  = run('git', 'pull', :cwd($save-as.IO.absolute));
            return $save-as if $pull-proc.exitcode == 0;
        }

        return False;
    }
}

my role GitExtractor {
    # EXTRACT (checkout) interface
    method extract-matcher($str) {
        my ($repo, $checkout) = $str.match(/^(.+?)['#' (.*)]?$/);
        return False unless $repo.IO.d;
        my $proc = run('git', 'status', :cwd($repo));
        $proc.exitcode == 0 ?? True !! False;
    }

    method extract($path, $work-tree) {
        my ($repo, $checkout) = $path.match(/^(.+?)['#' (.*)]?$/)>>.Str || return False;
        $checkout = $checkout.?chars ?? $checkout !! 'HEAD';
        return False unless $repo.IO.d && $repo.IO.child('.git').d;

        die "repo directory does not exist: {$repo}"
            unless $repo.IO.e && $repo.IO.d;
        die "\{$work-tree} folder does not exist and could not be created"
            unless ($work-tree.IO.d || mkdir($work-tree));

        my $sha-proc = run('git', 'rev-parse', $checkout, :cwd($repo), :out, :err);
        my $sha      = $sha-proc.out.slurp.lines.head;
        my $sha-dir  = $work-tree.IO.child($sha);
        die "Failed to checkout to directory: {$sha-dir}"
            unless ($sha-dir.IO.d || mkdir($sha-dir));

        my $co-proc  = run('git', '--work-tree', $sha-dir, 'checkout', $sha, '.', :cwd($repo), :out, :err);

        ($sha-proc.exitcode == 0 && $co-proc.exitcode == 0) ?? $sha-dir.absolute !! False;
    }

    method list($repo) {
        my $proc = $.run('git', 'ls-files', :cwd($repo), :out);
        my @extracted-paths = $proc.out.slurp(:close).lines;
        $proc.exitcode == 0 ?? @extracted-paths.grep(*.defined) !! ();
    }
}

class Zef::Service::Shell::git does Probeable does Messenger {
    also does GitFetcher;
    also does GitExtractor;

    method probe {
        state $probe = try { run('git', '--help', :out, :err).exitcode == 0 ?? True !! False };
        ?$probe;
    }
}
