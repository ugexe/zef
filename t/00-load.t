use v6;
use Test;
plan 1;

subtest {
    # most other modules loaded in Zef.pm6 itself
    use-ok('Zef');
    use-ok('Storage');
    use-ok('PathTools');

    use-ok('Zef::Process');
    use-ok('Zef::CLI');
}, 'Base package modules';
