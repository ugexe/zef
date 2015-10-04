use v6;
use Test;
plan 4;

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


subtest {
    use-ok('Zef::Net::HTTP::Grammar::RFC1035'),
        '1035: Domain Names - Implementatin and Specification';

    use-ok('Zef::Net::HTTP::Grammar::RFC3066'),
        '3066: Tags for Identification of Languages';

    use-ok('Zef::Net::HTTP::Grammar::RFC4647'),
        '4647: Matching of Language Tags';

    use-ok('Zef::Net::HTTP::Grammar::RFC5322'),
        '5322: Internet Message Format';

    use-ok('Zef::Net::HTTP::Grammar::RFC5646'),
        '5646: Tags for Identifying Languages';

    use-ok('Zef::Net::HTTP::Grammar::RFC6265'),
        '6265: HTTP State Management Mechanism';

    use-ok('Zef::Net::HTTP::Grammar::RFC6854'),
        '6854: Update to Internet Message Format to Allow Group Syntax in the "From:" and "Sender:" Header Fields';

    use-ok('Zef::Net::HTTP::Grammar::RFC7230'),
        '7230: HTTP/1.1 Message Syntax and Routing';

    use-ok('Zef::Net::HTTP::Grammar::RFC7231'),
        '7231: Hypertext Transfer Protocol (HTTP/1.1): Semantics and Content';

    use-ok('Zef::Net::HTTP::Grammar::RFC7232'),
        '7232: Hypertext Transfer Protocol (HTTP/1.1): Conditional Requests';

    use-ok('Zef::Net::HTTP::Grammar::RFC7233'),
        '7233: Hypertext Transfer Protocol (HTTP/1.1): Range Requests';

    use-ok('Zef::Net::HTTP::Grammar::RFC7234'),
        '7234: Hypertext Transfer Protocol (HTTP/1.1): Caching';

    use-ok('Zef::Net::HTTP::Grammar::RFC7235'),
        '7235: Hypertext Transfer Protocol (HTTP/1.1): Authentication';
}, 'HTTP Grammars';
