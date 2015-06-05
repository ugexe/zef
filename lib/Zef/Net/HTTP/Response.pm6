use Zef::Net::HTTP::Grammar;
use Zef::Net::HTTP::Actions;


# A http response object built from HTTP::Grammar
class Zef::Net::HTTP::Response {
    has $.grammar;
    has $.message;
    has $.status-code = Int;
    has $.status-message;
    has $.chunked;
    has $.encoding;
    has $.body;
    has %.header;
    has $!header-chunk;
    has $.header-grammar;

    submethod BUILD(:$!message, :$!header-chunk) {
        my $actions = Zef::Net::HTTP::Actions.new;
        $!header-grammar = Zef::Net::HTTP::Grammar.parse($!header-chunk, :rule("TOP-Header"), :$actions) if $!header-chunk;
        $!grammar = Zef::Net::HTTP::Grammar.parse($!message, :$actions) if $!message;

        if my $g = $!grammar ?? $!grammar.<HTTP-message> !! $!header-grammar ?? $!header-grammar.<HTTP-header> !! False {
            $!status-code    =  ($g.<start-line>.<status-line>.<status-code>   // Int).Int;
            $!status-message = ~($g.<start-line>.<status-line>.<reason-phrase> //  '');
            $!body           = ~($g.<message-body>                             //  '') if $!grammar;

 
            %!header = $g.<header-field>>>.made;
            if %!header<Transfer-Encoding>:exists && %!header<Transfer-Encoding> ~~ /^chunked/ {
                # todo: check submatch "transfer-codings" to get each individual coding instead of the substring match
                $!chunked = 1;
            }

            if %!header<Content-Type>.hash -> %ct {
                my @text-subtypes = <text html xhtml xml atom json javascript rss soap>;
                if %ct.<type> eq 'text' || %ct.<subtype> ~~ any(@text-subtypes) {
                    $!encoding = %ct.<parameters>.<charset> // 'utf-8';
                }
            }
        }
    }

    method Str {
        return $!grammar ?? $!grammar.Str !! Str;
    }

    method content {
        my $content = !$!chunked 
            ?? $!body
            !! do { 
                my $chunked-grammar = Zef::Net::HTTP::Grammar.subparse($.body, :rule<chunked-body>);
                my $c ~= $_.<chunk-data>.Str for $chunked-grammar.<chunk>.list;
                $c
            }        

        return $!encoding ?? try { $content.decode($!encoding) } !! $content;
    }
}