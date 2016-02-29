use Zef;

class Zef::Test does Pluggable {
    method test($path, :@includes, Supplier :$stdout, Supplier :$stderr) {
        die "Can't test non-existent path: {$path}" unless $path.IO.e;
        my $tester = self.plugins.first(*.test-matcher($path));
        die "No testing backend available" unless ?$tester;

        $tester.stdout.Supply.act: -> $out { ?$stdout ?? $stdout.emit($out) !! $*OUT.say($out) }
        $tester.stderr.Supply.act: -> $err { ?$stderr ?? $stderr.emit($err) !! $*ERR.say($err) }

        my @got = try $tester.test($path, :@includes);

        $tester.stdout.done;
        $tester.stderr.done;

        @got;
    }
}
