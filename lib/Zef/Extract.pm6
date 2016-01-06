use Zef;

class Zef::Extract does DynLoader {
    method extract($path, $extract-to) {
        die "Can't extract non-existent path: {$path}" unless $path.IO.e;
        die "Can't extract to non-existent path: {$extract-to}" unless $extract-to.IO.e;

        for self.plugins -> $extractor {
            if $extractor.extract-matcher($path) {
                my $got = $extractor.extract($path, $extract-to);
                return True;
            }
        }

        die "something went wrong extracting {$path} to {$extract-to} with {$.plugins.join(',')}";
    }

    method plugins {
        state @usable = @!backends\
            .grep({ (try require ::($ = $_<module>)) !~~ Nil })\
            .grep({ ::($ = $_<module>).^can("probe") ?? ::($ = $_<module>).probe !! True })\
            .map({ ::($ = $_<module>).new( |($_<options> // []) ) });
    }
}
