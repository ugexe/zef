use v6;
use Test;
plan 4;

use Zef::Net::HTTP::Grammar;


subtest {
    my $request =  q{GET /http.html HTTP/1.1}
        ~ "\r\n" ~ q{Host: www.http.header.free.fr}
        ~ "\r\n" ~ q{Accept: image/gif; q=0.1, image/x-xbitmap, image/jpeg, image/pjpeg,}
        ~ "\r\n" ~ q{Accept-Language: da, en-gb;q=0.9}
        ~ "\r\n" ~ q{Accept-Encoding: gzip, deflate}
        ~ "\r\n" ~ q{User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)}
        ~ "\r\n" ~ q{Connection: Keep-Alive}
        ~ "\r\n\r\n";

    my $http = Zef::Net::HTTP::Grammar.parse($request);

    is $http.<HTTP-message>.<start-line>.<request-line>.<method>, 'GET';
    is $http.<HTTP-message>.<start-line>.<request-line>.<request-target>, '/http.html';

    is $http.<HTTP-message>.<header-field>.[0], 'Host: www.http.header.free.fr';
    is $http.<HTTP-message>.<header-field>.[0].<name>, 'Host';
    is $http.<HTTP-message>.<header-field>.[0].<value>, 'www.http.header.free.fr';

    is $http.<HTTP-message>.<header-field>.[1].<name>, 'Accept';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<accept-value>.[0].<media-range>.<type>, 'image';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<accept-value>.[0].<media-range>.<subtype>, 'gif';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<accept-value>.[0].<accept-params>.<weight>.<qvalue>, '0.1';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<accept-value>.[1].<media-range>.<type>, 'image';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<accept-value>.[1].<media-range>.<subtype>, 'x-xbitmap';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<accept-value>.[2].<media-range>.<type>, 'image';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<accept-value>.[2].<media-range>.<subtype>, 'jpeg';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<accept-value>.[3].<media-range>.<type>, 'image';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<accept-value>.[3].<media-range>.<subtype>, 'pjpeg';

    is $http.<HTTP-message>.<header-field>.[2], 'Accept-Language: da, en-gb;q=0.9';
    is $http.<HTTP-message>.<header-field>.[2].<name>, 'Accept-Language';
    is $http.<HTTP-message>.<header-field>.[2].<value>.<accept-language-value>.[0].<language-range>.<language-tag>, 'da';
    is $http.<HTTP-message>.<header-field>.[2].<value>.<accept-language-value>.[0].<language-range>.<language-tag>.<primary-subtag>, 'da';
    is $http.<HTTP-message>.<header-field>.[2].<value>.<accept-language-value>.[1].<language-range>.<language-tag>, 'en-gb';
    is $http.<HTTP-message>.<header-field>.[2].<value>.<accept-language-value>.[1].<language-range>.<language-tag>.<primary-subtag>, 'en';
    is $http.<HTTP-message>.<header-field>.[2].<value>.<accept-language-value>.[1].<language-range>.<language-tag>.<subtag>, 'gb';

    is $http.<HTTP-message>.<header-field>.[3], 'Accept-Encoding: gzip, deflate';
    is $http.<HTTP-message>.<header-field>.[3].<name>, 'Accept-Encoding';
    is $http.<HTTP-message>.<header-field>.[3].<value>.<accept-encoding-value>.[0].<codings>, 'gzip';
    is $http.<HTTP-message>.<header-field>.[3].<value>.<accept-encoding-value>.[1].<codings>, 'deflate';

    is $http.<HTTP-message>.<header-field>.[4], 'User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)';
    is $http.<HTTP-message>.<header-field>.[4].<name>, 'User-Agent';
    is $http.<HTTP-message>.<header-field>.[4].<value>, 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)';

    is $http.<HTTP-message>.<header-field>.[5], 'Connection: Keep-Alive';
    is $http.<HTTP-message>.<header-field>.[5].<name>, 'Connection';
    is $http.<HTTP-message>.<header-field>.[5].<value>, 'Keep-Alive';
}, 'Basic Request';

subtest {
    my $response = q{HTTP/1.1 200 OK}
        ~ "\r\n" ~ q{Allow: GET, HEAD, PUT}
        ~ "\r\n" ~ q{Content-Type: text/html; charset=utf-8}
        ~ "\r\n" ~ q{Transfer-Encoding: chunked, gzip}
        ~ "\r\n\r\n";

    my $http = Zef::Net::HTTP::Grammar.parse($response);


    is $http.<HTTP-message>.<header-field>.[0], 'Allow: GET, HEAD, PUT';
    is $http.<HTTP-message>.<header-field>.[0].<name>, 'Allow';
    is $http.<HTTP-message>.<header-field>.[0].<value>.<allow-value>.[0].<method>, 'GET';
    is $http.<HTTP-message>.<header-field>.[0].<value>.<allow-value>.[1].<method>, 'HEAD';
    is $http.<HTTP-message>.<header-field>.[0].<value>.<allow-value>.[2].<method>, 'PUT';

    is $http.<HTTP-message>.<header-field>.[1], 'Content-Type: text/html; charset=utf-8';
    is $http.<HTTP-message>.<header-field>.[1].<name>, 'Content-Type';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<media-type>, 'text/html; charset=utf-8';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<media-type>.<type>, 'text';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<media-type>.<subtype>, 'html';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<media-type>.<parameter>.[0].<name>, 'charset';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<media-type>.<parameter>.[0].<value>, 'utf-8';

    is $http.<HTTP-message>.<header-field>.[2], 'Transfer-Encoding: chunked, gzip';
    is $http.<HTTP-message>.<header-field>.[2].<name>, 'Transfer-Encoding';
    is $http.<HTTP-message>.<header-field>.[2].<value>.<transfer-encoding-value>.[0].<transfer-coding>, 'chunked';
    is $http.<HTTP-message>.<header-field>.[2].<value>.<transfer-encoding-value>.[1].<transfer-coding>, 'gzip';
}, 'HTTP-message: Basic Response';


subtest {
    my $response = q{HTTP/1.1 200 OK}
        ~ "\r\n" ~ q{Server: nginx/1.2.1}
        ~ "\r\n" ~ q{Date: Thu, 07 May 2015 03:58:14 GMT}
        ~ "\r\n" ~ q{Content-Type: application/json;charset=UTF-8}
        ~ "\r\n" ~ q{Content-Length: 48}
        ~ "\r\n" ~ q{Connection: close}
        ~ "\r\n" ~ q{}
        ~ "\r\n" ~ q{message body};

    my $http = Zef::Net::HTTP::Grammar.parse($response);

    ok $http;
    is $http.<HTTP-message>.<start-line>.<status-line>.<status-code>, 200, 'Status code matches';
    is $http.<HTTP-message>.<start-line>.<status-line>.<reason-phrase>, 'OK', 'Status message matches';
    is $http.<HTTP-message>.<message-body>, 'message body', "Got body";
}, 'HTTP-message: Zef.pm basic';



subtest {
    my $response = q{HTTP/1.1 200 OK}
        ~"\r\n" ~ q{Date: Mon, 25 May 2015 21:06:46 GMT}
        ~"\r\n" ~ q{Server: Perl Dancer 1.3132}
        ~"\r\n" ~ q{Content-Length: 5}
        ~"\r\n" ~ q{Content-Type: text/html}
        ~"\r\n" ~ q{X-Powered-By: Perl Dancer 1.3132}
        ~"\r\n" ~ q{Vary: Accept-Encoding}
        ~"\r\n" ~ q{Connection: close}
        ~"\r\n" ~ q{}
        ~"\r\n" ~ q{48092};

    my $http = Zef::Net::HTTP::Grammar.parse($response);
    my $content-length = $http.<HTTP-message>.<header-field>.cache.first({ $_.<name> eq 'Content-Length' }).<value>;

    is $content-length, 5, 'Content-Length correct value';
    is $http.<HTTP-message>.<message-body>, 48092, "Report Number parsed from body";
}, 'HTTP-message: P6C mock test report response';
