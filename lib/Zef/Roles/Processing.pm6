use Zef::Process;

role Zef::Roles::Processing[Int :$jobs, Bool :$force] {
    has @.processes;
    has $.jobs = $jobs;

    method queue-processes(*@groups) {
        my %env = %*ENV.hash;
        my $p6lib = (%env<PERL6LIB>.list, @.perl6lib.list).flat.grep(*.so).join(',');
        %env<PERL6LIB> = $p6lib if $p6lib.so;

        my @procs;
        for @groups.flat -> $group {
            for $group.flat -> @execute {
                my @args    = flat @execute;
                my $command = @args.shift;
                @procs.push: Zef::Process.new(:$command, :@args, :async(?$jobs), cwd => $.path, :%env);
            }
        }

        @!processes.push($(@procs)) if @procs.elems;
        return $(@procs);
    }

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
        for @!processes.flat -> @group {
            my @group-promises;
            for @group.flat.grep(!*.started) -> $process {
                @promises.push: @group-promises.push: $process.start;

                if $jobs && @group-promises == $jobs {
                    await Promise.anyof(@group-promises);
                    @group-promises .= grep({ !$_ });
                }
                LAST { await Promise.allof(@group-promises) }
            }
        }
        @promises.elems ?? Promise.allof(@promises) !! do { my $p = Promise.new; $p.keep; $p };
    }

    #method tap(&code) { @!processes>>.tap(&code)          }
    method passes     {
        gather for @!processes -> @group {
            take $_.id for @group.grep(*.ok.so);
        }
    }
    method failures   {
        gather for @!processes -> @group {
            take $_.id for @group.grep(*.ok.not);
        }
    }

    method i-paths {
        return flat ($.precomp-path, $.source-path, @.includes)\
            .grep(*.so).unique\
            .map({ ?$_.IO.is-relative ?? $_.IO.relative !! $_.IO.relative($.path) })\
            .map({ qqw/-I$_/ });
    }
}