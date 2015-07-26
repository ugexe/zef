use Zef::Utils::PathTools;

role Zef::Roles::Testing {
    method test-cmds(Bool :$shuffle) {
        my @i-paths    = ($.precomp-path, $.source-path, @.includes)\
            .grep(*.so).unique\
            .map({ ?$_.IO.is-relative ?? $_.IO !! $_.IO.relative($.path) })\
            .map({ qqw/-I$_/ });
        my $test-dir   = $.path.IO.child('t');
        my @test-files = $test-dir.ls(:r, :f)\
            .grep(*.extension eq 't')\
            .map({ ?$_.IO.is-relative ?? $_.IO.relative !! $_.IO.relative($.path).IO });
        @test-files = ?$shuffle ?? @test-files.pick(*) !! @test-files.sort;

        my @cmds = @test-files.map: { [$*EXECUTABLE, '--ll-exception', @i-paths, $_] };
        return @cmds;
    }
}
