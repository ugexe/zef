use v6;
use Test;
plan 2;

use Zef::Grammars::HTTP::RFC7230;

subtest {
    my $header-text = q{GET /http.html HTTP/1.1}
        ~ "\r\n" ~ q{Host: www.http.header.free.fr}
        ~ "\r\n" ~ q{Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg,}
        ~ "\r\n" ~ q{Accept-Language: Fr}
        ~ "\r\n" ~ q{Accept-Encoding: gzip, deflate}
        ~ "\r\n" ~ q{User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)}
        ~ "\r\n" ~ q{Connection: Keep-Alive}
        ~ "\r\n\r\n";

    my $header = Zef::Grammars::HTTP::RFC7230.parse($header-text);

    is $header.<HTTP-message>.<start-line>.<request-line>.<method>, 'GET';
    is $header.<HTTP-message>.<start-line>.<request-line>.<request-target>, '/http.html';

    is $header.<HTTP-message>.<header-field>.[0], 'Host: www.http.header.free.fr';
    is $header.<HTTP-message>.<header-field>.[0].<name>, 'Host';
    is $header.<HTTP-message>.<header-field>.[0].<value>, 'www.http.header.free.fr';

    is $header.<HTTP-message>.<header-field>.[1], 'Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg,';
    is $header.<HTTP-message>.<header-field>.[1].<name>, 'Accept';
    is $header.<HTTP-message>.<header-field>.[1].<value>.[0], 'image/gif';
    is $header.<HTTP-message>.<header-field>.[1].<value>.[1], 'image/x-xbitmap';
    is $header.<HTTP-message>.<header-field>.[1].<value>.[2], 'image/jpeg';
    is $header.<HTTP-message>.<header-field>.[1].<value>.[3], 'image/pjpeg';

    is $header.<HTTP-message>.<header-field>.[2], 'Accept-Language: Fr';
    is $header.<HTTP-message>.<header-field>.[2].<name>, 'Accept-Language';
    is $header.<HTTP-message>.<header-field>.[2].<value>, 'Fr';

    is $header.<HTTP-message>.<header-field>.[3], 'Accept-Encoding: gzip, deflate';
    is $header.<HTTP-message>.<header-field>.[3].<name>, 'Accept-Encoding';
    is $header.<HTTP-message>.<header-field>.[3].<value>.[0], 'gzip';
    is $header.<HTTP-message>.<header-field>.[3].<value>.[1], 'deflate';

    is $header.<HTTP-message>.<header-field>.[4], 'User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)';
    is $header.<HTTP-message>.<header-field>.[4].<name>, 'User-Agent';
    is $header.<HTTP-message>.<header-field>.[4].<value>, 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)';

    is $header.<HTTP-message>.<header-field>.[5], 'Connection: Keep-Alive';
    is $header.<HTTP-message>.<header-field>.[5].<name>, 'Connection';
    is $header.<HTTP-message>.<header-field>.[5].<value>, 'Keep-Alive';
}, 'Basic';

subtest {
    my $header-text = q{HTTP/1.1 200 OK}
        ~ "\r\n" ~ q{Server: nginx/1.2.1}
        ~ "\r\n" ~ q{Date: Thu, 07 May 2015 03:58:14 GMT}
        ~ "\r\n" ~ q{Content-Type: application/json;charset=UTF-8}
        ~ "\r\n" ~ q{Content-Length: 48}
        ~ "\r\n" ~ q{Connection: close}; # No ending \r\n or message body

    my $header = Zef::Grammars::HTTP::RFC7230.parse($header-text);

    ok $header;
    is $header.<HTTP-message>.<start-line>.<status-line>.<status-code>, 200, 'Status code matches';
    is $header.<HTTP-message>.<start-line>.<status-line>.<reason-phrase>, 'OK', 'Status message matches';
}, 'Zef.pm basic';

done();
