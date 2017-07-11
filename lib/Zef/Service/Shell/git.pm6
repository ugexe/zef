use Zef;
use Zef::Utils::URI;

my role GitFetcher {
    has $.scheme;

    # FETCH (clone/pull) INTERFACE
    method fetch-matcher($url) {
        return $url.starts-with('git://' | 'http' | 'ssh') && $url.path.match(/'.git'[\/|\#.*?]?$/);
    }

    multi method fetch($orig-url, $save-as) {
        # allow overriding the default scheme of git urls
        my ($url, $checkout) = |($!scheme ?? $orig-url.subst(/^\w+ '://'/, "{$!scheme}://") !! $orig-url).match(/^(.*?)[\/|\#(.*?)]?$/);

        my $clone-proc := zrun('git', 'clone', $url, $save-as.IO.absolute, '--quiet', :!out, :!err, :cwd($save-as.IO.parent));
        my $pull-proc  := zrun('git', 'pull', '--quiet', :!out, :!err, :cwd($save-as.IO.absolute));

        return ($clone-proc.so || $pull-proc.so) ?? $save-as !! False;
    }
}

my role GitExtractor {
    # EXTRACT (checkout) interface
    method extract-matcher($str) {
        my ($repo, $checkout) = |$str.match(/^(.*?)[\/|\#(.*?)]?$/);
        return False unless $str.IO.d;
        my $proc = zrun('git', 'status', :!out, :!err, :cwd($str));
        $proc.so;
    }

    method extract($path, $work-tree) {
        my ($repo, $checkout) = |$path.match(/^(.*?)[\/|\#(.*?)]?$/)|| return False;
        $checkout = $checkout.?chars ?? $checkout !! 'HEAD';
        return False unless $path.IO.d && $path.IO.child('.git').d;

        die "repo directory does not exist: {$path}"
            unless $path.IO.e && $path.IO.d;
        die "\{$work-tree} folder does not exist and could not be created"
            unless ($work-tree.IO.d || mkdir($work-tree));

        my $sha-proc = zrun('git', 'rev-parse', $checkout, :cwd($path), :out, :!err);
        my @out      = $sha-proc.out.lines;
        $sha-proc.out.close;

        my $sha      = @out[0];
        my $sha-dir  = $work-tree.IO.child($sha);
        die "Failed to checkout to directory: {$sha-dir}"
            unless ($sha-dir.IO.d || mkdir($sha-dir));

        my $co-proc  = zrun('git', '--work-tree', $sha-dir, 'checkout', $sha, '.', :cwd($path), :!out, :!err);

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
