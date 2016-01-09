use Zef;

class Zef::Test does DynLoader {
    method test($path) {
        die "Can't test non-existent path: {$path}" unless $path.IO.e;
        for self.plugins -> $tester {
            if $tester.test-matcher($path) {
                my $got = $tester.test($path);
                die "something went wrong testing {$path} with {$tester}" unless ?$got;
                return True;
            }
        }
    }

    method plugins {
        state @usable = @!backends\
            .grep({ !$_<disabled> })\
            .grep({ (try require ::($ = $_<module>)) !~~ Nil })\
            .grep({ ::($ = $_<module>).^can("probe") ?? ::($ = $_<module>).probe !! True })\
            .map({ ::($ = $_<module>).new( |($_<options> // []) ) });
    }
}
