use Zef::Net::HTTP;
use Zef::Net::HTTP::Grammar;
use Zef::Net::HTTP::Actions;


# A http response object built from HTTP::Grammar
class Zef::Net::HTTP::Response does HTTP::Response {
    # start-line
    has $.status-code = Int;
    has $.status-message;

    # the raw data for each of these sections
    has $.header;
    has $.body;
    has $.trailer;

    # the raw data in structured form
    has %.headers;
    has %.trailers;

    has $.header-grammar;
    has $.trailer-grammar;

    # easy access to common options. temporary?
    has $.chunked;
    has $.encoding;


    submethod BUILD(Str :$!header!, :$!body, :$!trailer) {
        my $actions = Zef::Net::HTTP::Actions.new;
        if Zef::Net::HTTP::Grammar.parse($!header, :rule("TOP-headers"), :$actions) -> $hg {
            $!header-grammar := $hg.<HTTP-headers>;
        }

        # todo: parse each header one at a time instead of all at once
        if $!header-grammar {
            $!status-code    =  ($!header-grammar.<start-line>.<status-line>.<status-code>   // Int).Int;
            $!status-message = ~($!header-grammar.<start-line>.<status-line>.<reason-phrase> //  '');

            %!headers = $!header-grammar.<header-field>>>.made;

            for %!headers<Transfer-Encoding>.grep(*.so).cache -> $te {
                given $te {
                    when /^chunked/ { $!chunked = 1                           }
                    default         { fail "'{$te}' Transfer-Encoding is NYI" }
                }
            }

            # todo: contribute something similiar to HTTP::UserAgent (beyond how it currently checks this)
            if %!headers<Content-Type>.hash -> %ct {
                my @text-subtypes := <text html xhtml xml atom json javascript rss soap>;
                if %ct.<type> eq 'text' || %ct.<subtype> ~~ any(@text-subtypes) {
                    $!encoding = %ct.<parameters>.<charset> // 'utf-8';
                }
            }
        }
    }

    method Str {
        return $!header.Str;
    }

    # Apply transfer codings, content encoding, etc to the body data
    method content(Bool :$bin) {
        my @buf;
        $!body.tap: {@buf.push($_) for $_.cache}
        await $!body.done;
        my $data = buf8.new(@buf);

        my $content = ?$!chunked ?? ChunkedReader($data) !! $data;
        return buf8.new($data) if ?$bin;
        return ?$!encoding ?? $content.decode($!encoding) !! $content;
    }
}
