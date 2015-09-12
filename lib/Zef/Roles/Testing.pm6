use Zef::Utils::PathTools;

role Zef::Roles::Testing {
    method test-cmds(Bool :$shuffle) {
        my $test-dir   := $.path.IO.child('t');
        my @test-files  = $test-dir.ls(:r, :f)\
            .grep(*.extension eq 't')\
            .map({ ?$_.IO.is-relative ?? $_.IO.relative !! $_.IO.relative($.path).IO });
        @test-files = ?$shuffle ?? @test-files.pick(*) !! @test-files.sort;

        @test-files.map: { $($*EXECUTABLE, '--ll-exception', $.i-paths.cache, $_) }
    }
}
