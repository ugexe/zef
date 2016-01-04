unit module testutils;

our sub tmpdir is export {
    state $test-id += 1;
    my $dir = $*TMPDIR.child("{time}-{$*PID}-{$test-id}");
    mkdir($dir) unless $dir.IO.e;
    $dir;
}
