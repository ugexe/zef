unit module Zef::Utils::Path;

proto sub valid-path($) is export {*}
multi sub valid-path(IO::Path $path) { nextwith($path.abspath) }
multi valid-path(Str(Cool) $path) {
    my $io = $path.IO.abspath.IO;
    return True if "{$io}".IO.e;

    my $write-test-path = $io.child('foo');
    try $write-test-path.mkdir;
    if "{$io}".IO.e {
        try $write-test-path.rmdir;
        return True;
    }

    False;
}
