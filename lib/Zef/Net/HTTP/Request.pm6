use Zef::Net::URI;
use Zef::Utils::Base64;

# todo: generate class from grammar via actions

# A http request object that attempts to handle proxy and basic auth
class Zef::Net::HTTP::Request {
    has $.grammar;
    has $.action;
    has $.url;
    has $.uri;
    has $.payload;
    has $.proxy-url;
    has $.proxy-uri;
    has $!auth;

    submethod BUILD(:$!action!, :$!url!, :$!payload, :$!proxy-url, :$user, :$pass) {
        $!uri       = Zef::Net::URI.new(url => $!url);
        $!proxy-uri = Zef::Net::URI.new(url => $!proxy-url) if ?$!proxy-url;
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

