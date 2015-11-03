use v6;
use Test;
plan 3;

subtest {
    # most other modules loaded in Zef.pm6 itself
    use-ok('Zef');
    use-ok('Storage');
    use-ok('PathTools');

    use-ok('Zef::Process');
    use-ok('Zef::CLI');
}, 'Base package modules';

subtest {
    use-ok('Zef::Test::Grammar'),
        'Test Anything Protocol Specification';
}, 'TAP Grammars';


subtest {
    use-ok('Zef::Net::URI::Grammar::RFC3986'),
        '3986: Uniform Resource Identifier (URI): Generic Syntax';

    use-ok('Zef::Net::URI::Grammar::RFC4234'),
        '4234: Augmented BNF for Syntax Specifications: ABNF';
}, 'URI Grammars';
