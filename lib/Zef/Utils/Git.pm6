use Zef::Process;
# This is hacky as all hell and will be replaced by something proper in Zef::Net eventually
class Zef::Utils::Git {
    has @.flags = <--quiet>;

    method clone(:$save-to is copy = $*TMPDIR, *@urls) {
        gather for @urls -> $url {
            my $proc = Zef::Process.new(
                :command('git'), 
                :args('clone', @!flags, $url, $save-to.IO), 
                :cwd($save-to.IO.dirname),
                :!async,
            );
            await $proc.start;
            my $git_result = $proc.exitcode;

            given $git_result {
                when 128 { # directory already exists and is not empty                    
                    print "===> Folder exists: Attempting updating via `git pull`\n";
                    $proc = Zef::Process.new(
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

