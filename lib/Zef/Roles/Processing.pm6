use Zef::Process;

role Zef::Roles::Processing[Bool :$async] {
    has @.processes;

    method queue-processes(*@groups) {
        my %env = %*ENV.hash;
        %env<PERL6LIB> = (%env<PERL6LIB> // (), @.perl6lib).join(',');

        my @procs := @groups>>.map: -> $execute {
            my $command := $execute.list.[0];
            my @args    := $execute.list.elems > 1 ?? $execute.list.[1..*] !! ();
            Zef::Process.new(:$command, :@args, :$async, cwd => $.path, :%env);
        }
        @!processes.push: [@procs];
        return @procs;
    }

    method start-processes {
        my $p = Promise.new;
        $p.keep(1);

        for @!processes -> $level {
            $p = $p.then: {
                my @promises := $level.list.map: { $_.start }
                await Promise.allof(@promises);
            }
        }

        $p;
    }

    method tap(&code) { @!processes>>.tap(&code)          }
    method passes     { @!processes>>.grep(*.ok.so)>>.id  }
    method failures   { @!processes>>.grep(*.ok.not)>>.id }

    method i-paths {
        return ($.precomp-path, $.source-path, @.includes)\
            .grep(*.so).unique\
            .map({ ?$_.IO.is-relative ?? $_.IO.relative !! $_.IO.relative($.path) })\
            .map({ qqw/-I$_/ });
    }
}