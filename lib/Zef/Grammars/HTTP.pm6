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
            $!scheme    = ~($!grammar.<URI-reference>.<URI>.<scheme>                           //  '');
            $!host      = ~($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<host>     //  '');
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
    has $.status-code;
    has $.status-message;
    has $.body;
    has %.header;

    submethod BUILD(:$!message) {
        $!grammar = Zef::Grammars::HTTP::RFC7230.parse($!message) if $!message;

        if $!grammar {
            $!status-code    =  ($!grammar.<HTTP-message>.<start-line>.<status-line>.<status-code>   // Int).Int;
            $!status-message = ~($!grammar.<HTTP-message>.<start-line>.<status-line>.<reason-phrase> //  '');
            $!body           = ~($!grammar.<HTTP-message>.<message-body>                             //  '');

            for $!grammar.<HTTP-message>.<header-field>.list -> $field {
                %!header.{~$field.<name>} = ~$field.<value>;
            }
        }
    }

    method Str {
        return $!grammar.Str;
    }
}

class Zef::Grammars::HTTPRequest {
    has $.grammar;
    has $.action;
    has $.url;
    has $.uri;
    has $!auth-string;
    has $!auth-username;
    has $!auth-password;
    has $!payload;
    has $!proxy-auth-string;
    has $!proxy-auth-username;
    has $!proxy-auth-password;

    submethod BUILD(:$!action, :$!url, :$!payload, :$!auth-username, :$!auth-password, :$!proxy-auth-username, :$!proxy-auth-password) {
        my $encoder = Zef::Utils::Base64.new;

        $!uri = Zef::Grammars::URI.new(url => $!url);
        $!auth-string  = $!uri.user-info 
                            ?? $encoder.b64encode($!uri.user-info)
                            !! ($!auth-username && $!auth-password
                                ?? $encoder.b64encode("{$!auth-username}:{$!auth-password}")
                                !! Empty);
        $!proxy-auth-string = $encoder.b64encode("{$!proxy-auth-username}:{$!proxy-auth-password}") 
            if $!proxy-auth-username && $!proxy-auth-password;

    }

    method Str {
        my $req =        "$!action $!url HTTP/1.1"                          # request
            ~   "\r\n" ~ "Host: {$!uri.host}"                             # mandatory headers
            ~ (("\r\n" ~ "Content-Length: {$!payload.chars}") if $!payload) # optional header fields
            ~ (("\r\n" ~ "Proxy-Authorization: Basic {$!proxy-auth-string}") if $!proxy-auth-string)
            ~ (("\r\n" ~ "Authorization: Basic {$!auth-string}") if $!auth-string)
            ~   "\r\n" ~ "Connection: close\r\n\r\n"                      # last header field
            ~ ($!payload if $!payload);

        return $req;
    }
}
