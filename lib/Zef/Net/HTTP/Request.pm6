use Zef::Net::URI;
use Zef::Utils::Base64;

class Zef::Net::HTTP::Request {
    # start line
    has $.method;
    has $.url;
    has $.uri;
    has $!proto       = 'HTTP';
    has $!proto-major = 1;
    has $!proto-minor = 1;

    # header stuff
    has %.header;
    has %.trailer;
    has $.host;

    # payload
    has $.body;

    # additional stuff
    has $.proxy;

    submethod BUILD(
        :$!method = 'GET',
        :$!url!,
        :$!proxy where Bool|Str|Nil
    ) {
        $!uri = Zef::Net::URI.new(:$!url);
        fail "HTTP Scheme not supported: {$!uri.scheme}" unless $!uri.scheme ~~ any(<http https>);

        if ?$!proxy {
            if ?$!proxy.isa(Str) {
                $!proxy = Zef::Net::URI.new(url => $!proxy);
            }
            else {
                if my $p = %*ENV.{$!uri.scheme ~ '_proxy'} {
                    $!proxy = Zef::Net::URI.new(url => $p)
                }
                else {
                    fail ":\$proxy set to true, but \%*ENV<{$!uri.scheme}_proxy> not found";
                }
            }

            if ?$!proxy.uri.user-info {
                %!header<Proxy-Authorization> = "Basic " ~ b64encode($!proxy.uri.user-info);
            }
        }

        if $!uri.?user-info {
            %!header<Authorization> = "Basic " ~ b64encode($!uri.user-info);
        }

        %!header<Connection> = 'Close';
    }
    
    method Str {
        my $req = "$!method {?$!proxy ?? $!uri.Str !! $!uri.path} HTTP/1.1\r\n"
                  ~ "Host: {$!uri.host}\r\n"
                  ~ "Content-Length: {$!body ?? $!body.chars !! 0}\r\n"
                  ~ %!header.kv.map(->$key, $value { "{$key}: {$value}" }).join("\r\n")
                  ~ "\r\n\r\n" # \r\n\r\n marks the end of headers
                  ~ ($!body // '');
        return $req;
    }
}
