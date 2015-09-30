use Zef::Process;

role Zef::Roles::Processing[Int :$jobs, Bool :$force] {
    has @.processes;
    has $.jobs = $jobs;


    # todo: tag processes with their phase so as to simplify checking failures.
    # Recent update reusing previously created $dist, for instance, may show
    # build failures as test failures as well (this might be the correct/wanted result,
    # but in case its not we would then have a way around it).
    method queue-processes(*@groups) {
        my %env = %*ENV.hash;
        my $p6lib = (%env<PERL6LIB>.cache, @.perl6lib.cache).flat.grep(*.so).join(',');
        %env<PERL6LIB> = $p6lib if $p6lib.so;

        my @procs;
        for @groups -> $group {
            for $group.cache -> @execute {
                my @args    = flat @execute;
                my $command = @args.shift;
                @procs.append: Zef::Process.new(:$command, :@args, :async(?$jobs), cwd => $.path, :%env);
            }
        }

        @!processes.append($(@procs)) if @procs.elems;
        return $(@procs);
    }

    # todo: allow starting processes of a specific phase only
    method start-processes {
        # osx bug RT125758
        #my $p = Promise.new;
        #$p.keep(1);
        #
        #for @!processes -> $level {
        #    my @not-started := $level.cache.grep({ !$_.started });
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
                @promises.append: @group-promises.append: $process.start;

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
        return ($.precomp-path, $.source-path, @.includes)\
            .flat\
            .grep(*.so)\
            .map({ ?$_.IO.is-relative ?? $_.IO.relative !! $_.IO.relative($.path) })\
            .map({ qqw/-I$_/ })\
            .unique\
            .cache;
    }
}