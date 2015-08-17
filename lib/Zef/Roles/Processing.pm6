use Zef::Process;

role Zef::Roles::Processing[Bool :$async, Bool :$force] {
    has @.processes;
    has $.async = $async;

    method queue-processes(*@groups) {
        my %env = %*ENV.hash;
        %env<PERL6LIB> = (%env<PERL6LIB> // (), @.perl6lib).join(',');

        my @procs = @groups.grep(*.so).map: -> $group {
            my $p = $group.map(-> $execute {
                my $command = $execute.[0];
                my @args    = $execute.elems > 1 ?? $execute.[1..*].grep(*.so) !! ();
                Zef::Process.new(:$command, :@args, :$async, cwd => $.path, :%env);
            });
            $p;
        }

        @!processes.push($(@procs)) if @procs.elems;
        return $(@procs);
    }

    # todo: find a way to close/flush the stdout/err before it proceeds to the next step.
    # Currently, --async can result in the test result message (i.e. Testing OK ...)
    # being printed to screen before the test's output has been completely written.
    method start-processes {
        # osx bug RT125758
        #my $p = Promise.new;
        #$p.keep(1);
        #
        #for @!processes -> $level {
        #    my @not-started := $level.list.grep({ !$_.started });
        #    $p = $p.then: {
        #        my @promises := @not-started.map: { $_.start }
        #        await Promise.allof(@promises) if @promises;
        #    }
        #}
        #
        #$p;
        my @promises;
        for @!processes -> $group {
            my @new-promises = gather for $group.list -> $item {
                for $item.list { take $_.start unless $_.started };
            }
            @promises.push($_) for @new-promises;
            await Promise.allof(@new-promises) if @new-promises;
        }
        @promises.elems ?? Promise.allof(@promises) !! do { my $p = Promise.new; $p.keep; $p };
    }

    #method tap(&code) { @!processes>>.tap(&code)          }
    method passes     {
        gather for @!processes -> $group {
            for $group.list -> $item {
                for $item.list { take $_.id if $_.ok.so }
            }
        }
    }
    method failures   {
        gather for @!processes -> $group {
            for $group.list -> $item {
                for $item.list { take $_.id if $_.ok.not }
            }
        }
    }

    method i-paths {
        return ($.precomp-path, $.source-path, @.includes)\
            .grep(*.so).unique\
            .map({ ?$_.IO.is-relative ?? $_.IO.relative !! $_.IO.relative($.path) })\
            .map({ qqw/-I$_/ });
    }
}