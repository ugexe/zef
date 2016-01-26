use Zef;
use Zef::Shell;
use Zef::Utils::URI;



# todo: proper association with extract phase/role
class Zef::Shell::git is Zef::Shell does Fetcher does Extractor does Probeable does Messenger {
    method probe {
        state $git-probe = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }
            my $proc = zrun('git', '--help', :out);
            my $nl   = Buf.new(10).decode;
            my @out <== grep *.so <== split $nl, $proc.out.slurp-rest;
            $proc.out.close;
            $ = ?$proc;
        }
        ?$git-probe;
    }


    # FETCH (clone/pull) INTERFACE
    method fetch-matcher($url) {
        if uri($url) -> $uri {
            return True if $uri.scheme.starts-with('git') || $uri.path.ends-with('.git');
        }
        False;
    }

    method fetch($url, $save-as) {
        my $clone-proc := $.zrun('git', 'clone', $url, $save-as, '--quiet', :cwd($save-as.IO.dirname));
        my $pull-proc  := $.zrun('git', 'pull', '--quiet', :cwd($save-as));

        return ?$clone-proc || ?$pull-proc ?? $save-as !! False;
    }


    # EXTRACT (checkout) interface
    method extract-matcher($str) {
        my ($path, $checkout) = $str.match(/^(.+?)['#' (.*)]?$/);
        return False unless $path.IO.d && $path.IO.child('.git').d;
        True;
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
        $sha-proc.out.close;
        my $sha      = @out[0];
        my $sha-dir  = $work-tree.IO.child($sha);
        die "Failed to checkout to directory: {$sha-dir}"
            unless ($sha-dir.IO.d || mkdir($sha-dir));

        my $co-proc  = $.zrun('git', '--work-tree', $sha-dir, 'checkout', $sha, '.', :cwd($repo));
        (?$sha-proc && ?$co-proc) ?? $sha-dir.absolute !! False;
    }

    method list($repo) {
        my $proc = $.zrun('git', 'ls-files', :cwd($repo), :out);
        my @extracted-paths = $_ for $proc.out.lines;
        $proc.out.close;
        @ = ?$proc ?? @extracted-paths.grep(*.defined) !! ();
    }
}
