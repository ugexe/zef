use Zef::Net::HTTP::Grammar;

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
        $!header-grammar = Zef::Net::HTTP::Grammar.parse($!header-chunk, :rule("TOP-Header")) if $!header-chunk;
        $!grammar = Zef::Net::HTTP::Grammar.parse($!message) if $!message;

        if my $g = $!grammar ?? $!grammar.<HTTP-message> !! $!header-grammar ?? $!header-grammar.<HTTP-header> !! False {
            $!status-code    =  ($g.<start-line>.<status-line>.<status-code>   // Int).Int;
            $!status-message = ~($g.<start-line>.<status-line>.<reason-phrase> //  '');
            $!body           = ~($g.<message-body>                             //  '') if $!grammar;

            for $g.<header-field>.list -> $field {
                # todo: recursively turn structure into objects
                my $h = $field.<name>;
                my $v = $field.<value>;
                %!header.{$h.Str} = $v.Str;

                if $h.Str eq 'Transfer-Encoding' && $v.grep({ $_.<transfer-coding> ~~ /^chunked/ }) {
                    $!chunked = 1;
                }
                if $h.Str eq 'Content-Type' {
                    my @charsets = $v.<media-type>.<parameter>.list.grep({ $_.<name> ~~ /^charset/ }).map({ $_.<value> });
                    $!encoding = @charsets[0] if @charsets;
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

        

        return $content;
    }
}