use Zef;

class Zef::Test does DynLoader {
    method test($path, :@includes, :&stdout = -> $o {$o.say}, :&stderr = -> $e {$e.say}) {
        die "Can't test non-existent path: {$path}" unless $path.IO.e;
        my $tester = self.plugins.first(*.test-matcher($path));
        die "No testing backend available" unless ?$tester;

        $tester.stdout.Supply.act(&stdout);
        $tester.stderr.Supply.act(&stderr);

        my $got = $tester.test($path, :@includes);

        $tester.stdout.done;
        $tester.stderr.done;

        die "something went wrong testing {$path} with {$tester}" unless ?$got;

        return True;
    }

    method plugins {
        state @usable = @!backends.grep({
                !$_<disabled>
            &&  ((try require ::($ = $_<module>)) !~~ Nil)
            &&  (::($ = $_<module>).^can("probe") ?? ::($ = $_<module>).probe !! True)
            ?? True !! False
        }).map: { ::($ = $_<module>).new( |($_<options> // []) ) }

    }
}
