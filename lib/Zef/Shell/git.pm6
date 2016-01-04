use Zef;
use Zef::Shell;

# todo: proper association with extract phase/role
class Zef::Shell::git is Zef::Shell does Fetcher does Probeable {
    method fetch-matcher($url) { $ = so ($url.lc.starts-with('git://') || $url.lc.ends-with('.git')) }

    # todo: fetch with --no-checkout and use the `extractor` role/phase to checkout a branch
    # method extract-matcher($path) { }

    method probe {
        # todo: check without spawning process (slow)
        state $git-help = try {
            CATCH {
                when X::Proc::Unsuccessful { return False }
                default { return False }
            }

            my $proc = zrun('git', '--help', :out);
            my $nl   = Buf.new(10).decode;
            my @out <== grep *.so <== split $nl, $proc.out.slurp-rest;
            $proc.out.close;
            $ = $proc.exitcode == 0 ?? @out !! False;
        }

        so $git-help;
    }

    method fetch($url, $save-as) {
        my $clone-proc := $.zrun('git', 'clone', $url, $save-as, '--quiet', :cwd($save-as.IO.dirname));
        my $pull-proc  := $.zrun('git', 'pull', '--quiet', :cwd($save-as));

        return ?$clone-proc || ?$pull-proc ?? $save-as !! False;
    }
}
