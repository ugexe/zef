use Zef::Phase::Getting;

role Zef::Phase::Git does Zef::Phase::Getting {
    has %.options;
    has @.flags = <--quiet>;


    multi method get(:$save-to = "$*TMPDIR.path/{time}", *@urls) {
        for @urls -> $url {
            my $cmd = "git clone " ~ @.flags.join(' ') ~ " $url {$save-to.IO.path}";
            my $git_result = shell($cmd).exit;

            given $git_result {
                when 128 {
                    # directory already exists and is not empty
                    say "Folder exists: updating via pull";
                    $git_result = shell("(cd {$save-to.IO.path} && git pull {@.flags.join(' ')})").exit;
                }
            }

            $git_result == 0 ?? True !! False;
        }
    }
}

