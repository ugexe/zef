use Zef::Phase::Testing;
use Zef::Utils::PathTools;

class Zef::Tester does Zef::Phase::Testing {
    method test(*@repos, :$lib = ['blib/lib','lib'], :$p6flags) {
        my @libs = gather for @repos -> $path { 
            for $lib.list -> $l {
                take $*SPEC.catdir($path, $l);
            }
        }

        my @results = eager gather for @repos -> $path {
            my @files = $path.IO.ls(:r, :f).grep(/\.t$/);
            my %meta  = try %(from-json( $*SPEC.catpath('', $path.IO, 'META.info').IO.slurp ));

            my @tests = @files.map(-> $test-file {
                my $test-file-rel = $*SPEC.abs2rel($test-file, $path);
                my $cmd = qq|(cd $path && prove -v -e "perl6 {$p6flags.list} {@libs.map({ qqw/-I$_/ })}" $test-file-rel 2>&1)|;
                my $proc = pipe( $cmd, :r );

                my $test-output = $proc.slurp-rest;
                my $test-result = shell($cmd).exitcode == 0 ?? 1  !! 0;

                { ok => $test-result, test-output => $test-output, file => $test-file, path => $path }
            });

            take {  
                ok     => ?( @tests.grep({ $_.<ok> == 1}) == @tests.elems ),
                path   => $path,
                tests  => @tests,
                module => %meta<name>,
            }
        }
        return @results;
    }
}

