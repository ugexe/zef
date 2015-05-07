use v6;
use Test;
plan 1;

subtest {
    lives_ok { use Zef::Grammars::HTTP::RFC3066 }, 
        '3066: Tags for Identification of Languages';

    lives_ok { use Zef::Grammars::HTTP::RFC3986 }, 
        '3986: Uniform Resource Identifier (URI): Generic Syntax';
    
    lives_ok { use Zef::Grammars::HTTP::RFC4234 },
        '4234: Augmented BNF for Syntax Specifications: ABNF';

    lives_ok { use Zef::Grammars::HTTP::RFC4647 },
        '4647: Matching of Language Tags';

    lives_ok { use Zef::Grammars::HTTP::RFC5322 }, 
        '5322: Internet Message Format';

    lives_ok { use Zef::Grammars::HTTP::RFC5646 }, 
        '5646: Tags for Identifying Languages';
    
    lives_ok { use Zef::Grammars::HTTP::RFC7230 }, 
        '7230: HTTP/1.1 Message Syntax and Routing';
    
    lives_ok { use Zef::Grammars::HTTP::RFC7231 }, 
        '7231: Hypertext Transfer Protocol (HTTP/1.1): Semantics and Content';

    lives_ok { use Zef::Grammars::HTTP::RFC7232 }, 
        '7232: Hypertext Transfer Protocol (HTTP/1.1): Conditional Requests';

    lives_ok { use Zef::Grammars::HTTP::RFC7233 }, 
        '7233: Hypertext Transfer Protocol (HTTP/1.1): Range Requests';

    lives_ok { use Zef::Grammars::HTTP::RFC7233 }, 
        '7234: Hypertext Transfer Protocol (HTTP/1.1): Caching';

    lives_ok { use Zef::Grammars::HTTP::RFC7233 }, 
        '7235: Hypertext Transfer Protocol (HTTP/1.1): Authentication';
}, 'Sanity tests';

done();
