use Zef::Net::HTTP;
use Zef::Net::URI;
use Zef::Utils::Base64;

class Zef::Net::HTTP::Request does HTTP::Request {
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

    has $.body;

    # todo: move proxy stuff into its own interface/class
    has $.proxy;

    submethod BUILD(
        :$!method = 'GET',
        :$!url!,
        :$!body,
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

    # TEMPORARY
    method content-length {
        do given $!body {
            return $_.bytes when Buf;
            return $_.chars when Str;
            default { 0 }
        }
    }
    method start-line     { $.DUMP(:start-line) }

    method DUMP(Bool :$start-line, Bool :$headers, Bool :$body, Bool :$trailers --> Str) {
        # Default to dumping everything, otherwise we dump what was specified
        my $all = ?(!$start-line && !$headers && !$body && !$trailers);

        my $req;

        # start-line
        $req ~= "$!method {?$!proxy ?? $!uri.Str !! $!uri.path} HTTP/1.1\r\n" 
            if $all || $start-line;

        # headers
        $req ~= "Host: {$!uri.host}\r\n"
                ~ "Content-Length: {$.content-length}\r\n"
                ~ %!header.kv.map(->$key, $value { "{$key}: {$value}" }).join("\r\n")
                ~ "\r\n\r\n" if %!header && ($all || $headers);

        # TEMPORARY
        $req ~= $.DUMP-BODY 
            if $!body && ($all || $body);

        $req ~= %!trailer.kv.map(->$key, $value { "{$key}: {$value}" }).join("\r\n") 
            if %!trailer && ($all || $trailers);

        return $req // '';
    }

    # TEMPORARY
    submethod DUMP-BODY {
        given $!body {
            return $_.perl  when Buf;
            return $_       when Str;
            return $_.bytes when .bytes;
        }
    }
}
