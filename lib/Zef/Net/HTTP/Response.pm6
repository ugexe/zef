use Zef::Net::HTTP;

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

    has $!encoding;
    has $!chunked;

    method Str {
        return $!header.Str;
    }

    # Apply transfer codings, content encoding, etc to the body data
    method content(Bool :$bin) {
        my @buf;
        $!body.tap: {@buf.append($_) for $_.cache}
        # $!body.wait if ?$!body;
        my $data = buf8.new(@buf);

        my $content = ?$!chunked ?? ChunkedReader($data) !! $data;
        return buf8.new($data) if ?$bin;
        return ?$!encoding ?? $content.decode($!encoding) !! $content;
    }
}
