use Zef::Phase::Building;
role Zef::Plugin::PreComp does Zef::Phase::Building {
    multi method pre-compile($path is copy) {
        say "path: $path";
        my $supply = Supply.new;
        my $channel = $supply.Channel;

        $supply.act: { say "found directory: $_"; $supply.emit($_) if $_.IO ~~ :d && $_ !~~ $path };
        $supply.act: {
            say "maybe file: $_";
            if $_.IO ~~ :f {
                say "found file: $_";
                my $dest = "blib/{$_.dirname}/{$_.basename}.{$*VM.precomp-ext}";
                my $cmd  = "$*EXECUTABLE --target={$*VM.precomp-target} --output=$dest $_";
                say "shell: $cmd";
                my $precomp = shell($cmd).exit == 0 ?? True  !! False;
            }
        }

        my $promise = start { my $x = $channel.receive; $x.say };
        $supply.emit($path);
        await $promise;
        say "done";
    }
}

