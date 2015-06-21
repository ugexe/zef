use Zef::Net::HTTP;
use Zef::Net::HTTP::Grammar;
use Zef::Net::HTTP::Actions;


# A http response object built from HTTP::Grammar
class Zef::Net::HTTP::Response does HTTP::Response {
    has $.grammar;
    has $.message;
    has $.status-code = Int;
    has $.status-message;
    has $.chunked;
    has $.encoding;
    has $.body;
    has %.header;
    has %.trailer;
    has $.header-chunk;
    has $.header-grammar;
    has $.trailer-chunk;
    has $.trailer-grammar;

    submethod BUILD(:$!message, :$!header-chunk, :$!body, :$!trailer-chunk) {
        my $actions = Zef::Net::HTTP::Actions.new;
        $!header-grammar = Zef::Net::HTTP::Grammar.parse($!header-chunk, :rule("TOP-header"), :$actions) if $!header-chunk;
        $!grammar = Zef::Net::HTTP::Grammar.parse($!message, :$actions) if $!message;

        if my $g = $!grammar ?? $!grammar.<HTTP-message> !! $!header-grammar ?? $!header-grammar.<HTTP-header> !! False {
            $!status-code    =  ($g.<start-line>.<status-line>.<status-code>   // Int).Int;
            $!status-message = ~($g.<start-line>.<status-line>.<reason-phrase> //  '');
            $!body         //= ~($g.<message-body>                             //  '') if $!grammar;

            %!header = $g.<header-field>>>.made;

            for %!header<Transfer-Encoding>.list -> $te {
                given $te {
                    when /^chunked/ { $!chunked = 1                           }
                    default         { fail "'{$te}' Transfer-Encoding is NYI" }
                }
            }

            # todo: contribute something similiar to HTTP::UserAgent (beyond how it currently checks this)
            if %!header<Content-Type>.hash -> %ct {
                my @text-subtypes = <text html xhtml xml atom json javascript rss soap>;
                if %ct.<type> eq 'text' || %ct.<subtype> ~~ any(@text-subtypes) {
                    $!encoding = %ct.<parameters>.<charset> // 'utf-8';
                }
            }
        }
    }

    method Str {
        return $!grammar ?? $!grammar.Str !! ($!header-grammar ?? $!header-grammar.Str !! Str);
    }

    # Apply transfer codings, content encoding, etc to the body data
    method content {
        my ($promise, $stream) = $!body.kv;
        await $promise;

        # Right now $stream is a list of multi-byte buf8s, so we may need to combine them
        my $data = buf8.new;
        $data ~= buf8.new($_) for $stream.list;

        my $content = $!chunked ?? ChunkedReader($data) !! $data;
        return $!encoding ?? $content>>.decode($!encoding).join !! $content;
    }
}
