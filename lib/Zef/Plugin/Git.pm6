use Zef::Phase::Getting;

role Zef::Plugin::Git does Zef::Phase::Getting {
    has %.options;
    has @.flags = <--quiet>;


    method get(:$save-to = $*TMPDIR, *@urls) {
        my @results = eager gather for @urls -> $url {
            my $cmd = "git clone " ~ @.flags.join(' ') ~ " $url {$save-to.IO.path}";
            my $git_result = shell($cmd).exitcode;
            given $git_result {
                when 128 { # directory already exists and is not empty
                    say "Folder exists: updating via pull";
                    $git_result = shell("(cd {$save-to.IO.path} && git pull {@.flags.join(' ')})").exitcode;
                }
            }

            take \%(url => $url, path => $save-to.IO.path, ok => $git_result ?? 1 !! 0)
        }

        return @results;
    }
}

