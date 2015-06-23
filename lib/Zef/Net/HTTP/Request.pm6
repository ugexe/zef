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

    # todo: move proxy stuff into its own interface/class
    has $.proxy;

    submethod BUILD(
        :$!method = 'GET',
        :$!url!,
        :$!body,
        :$!proxy where Bool|Str|Nil
    ) {
        $!uri = Zef::Net::URI.new(:$!url);

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
                %!headers<Proxy-Authorization> = "Basic " ~ b64encode($!proxy.uri.user-info);
            }
        }

        if $!uri.?user-info {
            %!headers<Authorization> = "Basic " ~ b64encode($!uri.user-info);
        }

        %!headers<Connection> = 'Close';
    }

    # TEMPORARY
    method content-length {
        do given $!body {
            when Buf { $_.bytes        }
            when Str { $_.encode.bytes }
            default { 0 }
        }
    }
    method start-line     { $.DUMP(:start-line) }

    method DUMP(Bool :$start-line, Bool :$headers, Bool :$body, Bool :$trailers --> Str) {
        # Default to dumping everything, otherwise we dump what was specified
        my $all = ?(!$start-line && !$headers && !$body && !$trailers);

        my $req;

        # start-line
        if $all || $start-line {
            $req ~= $!method                                                   ~ ' '
                  ~  (?$!proxy ?? ($!uri.Str || $!url) !! ($!uri.path || '/')) ~ ' '
                  ~ (!$!uri.query ?? '' !! ('?'~$!uri.query                ~ ' ')) 
                  ~ "HTTP/1.1\r\n"; 
        }

        # headers
        $req ~= "Host: {$!uri.host}\r\n"
                ~ "Content-Length: {$.content-length}\r\n"
                ~ %!headers.kv.map(->$key, $value { "{$key}: {$value}" }).join("\r\n")
                ~ "\r\n\r\n" if %!headers && ($all || $headers);

        # TEMPORARY
        $req ~= $.DUMP-BODY 
            if $!body && ($all || $body);

        $req ~= %!trailers.kv.map(->$key, $value { "{$key}: {$value}" }).join("\r\n") 
            if %!trailers && ($all || $trailers);

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

    method Str {
        self.DUMP(:headers);
    }
}
