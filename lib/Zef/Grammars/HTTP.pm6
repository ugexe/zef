use Zef::Grammars::HTTP::RFC3986; # uri
use Zef::Grammars::HTTP::RFC7230; # http
use Zef::Utils::Base64;
# These should probably be placed outside the Zef::Grammars namespace 
# after the structure is fleshed out further.

class Zef::Grammars::URI {
    has $.grammar;
    has $.url;
    has $.scheme;
    has $.user-info;
    has $.host;
    has $.port;
    has $.query;
    has $.fragment;
    has $.location;

    submethod BUILD(:$!url) {
        $!grammar = Zef::Grammars::HTTP::RFC3986.parse($!url) if $!url;

        if $!grammar {
            $!scheme    = ~($!grammar.<URI-reference>.<URI>.<scheme>                           //  '').lc;
            $!host      = ~($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<host>     //  '').lc;
            $!port      =  ($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<port>     // Int).Int;
            $!user-info = ~($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<userinfo> //  '');
        }
    }

    method Str {
        return $!grammar.Str;
    }
}

class Zef::Grammars::HTTPResponse {
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
        $!header-grammar = Zef::Grammars::HTTP::RFC7230.parse($!header-chunk, :rule("TOP-Header")) if $!header-chunk;
        $!grammar = Zef::Grammars::HTTP::RFC7230.parse($!message) if $!message;

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
                my $chunked-grammar = Zef::Grammars::HTTP::RFC7230.subparse($.body, :rule<chunked-body>);
                my $c ~= $_.<chunk-data>.Str for $chunked-grammar.<chunk>.list;
                $c
            }

        

        return $content;
    }
}


class Zef::Grammars::HTTPRequest {
    has $.grammar;
    has $.action;
    has $.url;
    has $.uri;
    has $!payload;
    has $.proxy-url;
    has $.proxy-uri;
    has $!auth;

    submethod BUILD(:$!action!, :$!url!, :$!payload, :$!proxy-url, :$user, :$pass) {
        $!uri       = Zef::Grammars::URI.new(url => $!url);
        $!proxy-uri = Zef::Grammars::URI.new(url => $!proxy-url) if ?$!proxy-url;
        $!auth      = b64encode($user ?? "$user:{$pass // ''}" !! $!uri.user-info) if $user || $!uri.user-info;
    }

    method Str {
        my $encoder = Zef::Utils::Base64.new;        
        my $req =        "$!action $!url HTTP/1.1"                          # request
            ~   "\r\n" ~ "Host: {$!uri.host}"                               # mandatory headers
            ~ (("\r\n" ~ "Content-Length: {$!payload.chars}") if $!payload) # optional header fields
            ~ (("\r\n" ~ "Proxy-Authorization: Basic {$encoder.b64encode($!proxy-uri.user-info)}") if ?$!proxy-uri && ?$!proxy-uri.user-info)
            ~ (("\r\n" ~ "Authorization: Basic {$!auth}") if ?$!auth)
            ~   "\r\n" ~ "Connection: close\r\n\r\n"                        # last header field
            ~ ($!payload if $!payload);

        return $req;
    }
}

