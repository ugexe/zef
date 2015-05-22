use v6;
use Test;
plan 1;

subtest {
    lives-ok { use Zef::Grammars::HTTP::RFC1035 }, 
        '1035: Domain Names - Implementatin and Specification';

    lives-ok { use Zef::Grammars::HTTP::RFC3066 }, 
        '3066: Tags for Identification of Languages';

    lives-ok { use Zef::Grammars::HTTP::RFC3986 }, 
        '3986: Uniform Resource Identifier (URI): Generic Syntax';
    
    lives-ok { use Zef::Grammars::HTTP::RFC4234 },
        '4234: Augmented BNF for Syntax Specifications: ABNF';

    lives-ok { use Zef::Grammars::HTTP::RFC4647 },
        '4647: Matching of Language Tags';

    lives-ok { use Zef::Grammars::HTTP::RFC5322 }, 
        '5322: Internet Message Format';

    lives-ok { use Zef::Grammars::HTTP::RFC5646 }, 
        '5646: Tags for Identifying Languages';

    lives-ok { use Zef::Grammars::HTTP::RFC6265 }, 
        '6265: HTTP State Management Mechanism';

    lives-ok { use Zef::Grammars::HTTP::RFC6854 }, 
        '6854: Update to Internet Message Format to Allow Group Syntax in the "From:" and "Sender:" Header Fields';
    
    lives-ok { use Zef::Grammars::HTTP::RFC7230 }, 
        '7230: HTTP/1.1 Message Syntax and Routing';
    
    lives-ok { use Zef::Grammars::HTTP::RFC7231 }, 
        '7231: Hypertext Transfer Protocol (HTTP/1.1): Semantics and Content';

    lives-ok { use Zef::Grammars::HTTP::RFC7232 }, 
        '7232: Hypertext Transfer Protocol (HTTP/1.1): Conditional Requests';

    lives-ok { use Zef::Grammars::HTTP::RFC7233 }, 
        '7233: Hypertext Transfer Protocol (HTTP/1.1): Range Requests';

    lives-ok { use Zef::Grammars::HTTP::RFC7234 }, 
        '7234: Hypertext Transfer Protocol (HTTP/1.1): Caching';

    lives-ok { use Zef::Grammars::HTTP::RFC7235 }, 
        '7235: Hypertext Transfer Protocol (HTTP/1.1): Authentication';
}, 'Sanity tests';

done();
