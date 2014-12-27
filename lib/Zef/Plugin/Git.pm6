use Zef::Phase::Getting;

role Clone does Zef::Phase::Getting {
    has %.options;
    has @.flags = <--quiet>;


    multi method get($url, $save_to = '') {
        my $cmd = "git clone " ~ @.flags.join(' ') ~ " $url $save_to ";
        my $git_result = shell($cmd).exit;

        given $git_result {
            when 128 {
                # directory already exists and is not empty
                say "Folder exists: updating via pull";
                $git_result = shell("(cd $save_to && git pull {@.flags.join(' ')})").exit;
            }
        }

        $git_result == 0 ?? True !! False;
    }
}

