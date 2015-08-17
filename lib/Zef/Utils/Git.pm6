use Zef::Process;
# This is hacky as all hell and will be replaced by something proper in Zef::Net eventually
class Zef::Utils::Git {
    has @.flags is rw = <--quiet>;

    method clone(:$branch, :$save-to is copy = $*TMPDIR, *@urls) {
        gather for @urls -> $url {
            my $proc = Zef::Process.new(
                :id("git $save-to"),
                :command('git'), 
                :args('clone', ?$branch ?? ('-b', $branch) !! (), $url, $save-to.IO, @!flags), 
                :cwd($save-to.IO.dirname),
                :!async,
            );
            await $proc.start;
            my $git_result = $proc.exitcode;

            given $git_result {
                when 128 { # directory already exists and is not empty
                    if $branch {
                        print "===> Attempting checkout `git checkout $branch {@!flags}`\n";
                        $proc = Zef::Process.new(
                            :id("git checkout"),
                            :command('git'),
                            :args('checkout', $branch, @!flags),
                            :cwd($save-to.IO),
                            :!async,
                        );
                        await $proc.start;
                    }

                    print "===> Attempting updating via `git pull`\n";
                    $proc = Zef::Process.new(
                        :id("git pull"),
                        :command('git'), 
                        :args('pull', @!flags),
                        :cwd($save-to.IO),
                        :!async,
                    );
                    await $proc.start;
                    $git_result = $proc.exitcode;
                }
            }

            take { url => $url, path => $save-to.IO.path, ok => $proc.ok }
        }
    }
}

