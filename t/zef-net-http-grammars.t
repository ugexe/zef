use v6;
use Test;
plan 3;

use Zef::Net::HTTP::Grammar;


subtest {
    my $response = q{GET /http.html HTTP/1.1}
        ~ "\r\n" ~ q{Host: www.http.header.free.fr}
        ~ "\r\n" ~ q{Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg,}
        ~ "\r\n" ~ q{Accept-Language: Fr}
        ~ "\r\n" ~ q{Accept-Encoding: gzip, deflate}
        ~ "\r\n" ~ q{User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)}
        ~ "\r\n" ~ q{Connection: Keep-Alive}
        ~ "\r\n\r\n";

    my $http = Zef::Net::HTTP::Grammar.parse($response);

    is $http.<HTTP-message>.<start-line>.<request-line>.<method>, 'GET';
    is $http.<HTTP-message>.<start-line>.<request-line>.<request-target>, '/http.html';

    is $http.<HTTP-message>.<header-field>.[0], 'Host: www.http.header.free.fr';
    is $http.<HTTP-message>.<header-field>.[0].<name>, 'Host';
    is $http.<HTTP-message>.<header-field>.[0].<value>, 'www.http.header.free.fr';

    is $http.<HTTP-message>.<header-field>.[1], 'Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg,';
    is $http.<HTTP-message>.<header-field>.[1].<name>, 'Accept';

    is $http.<HTTP-message>.<header-field>.[1].<value>.<media-range>.[0], 'image/gif';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<media-range>.[1], 'image/x-xbitmap';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<media-range>.[2], 'image/jpeg';
    is $http.<HTTP-message>.<header-field>.[1].<value>.<media-range>.[3], 'image/pjpeg';

    is $http.<HTTP-message>.<header-field>.[2], 'Accept-Language: Fr';
    is $http.<HTTP-message>.<header-field>.[2].<name>, 'Accept-Language';
    is $http.<HTTP-message>.<header-field>.[2].<value>.<language-range>.[0].<language-tag>, 'Fr';

    is $http.<HTTP-message>.<header-field>.[3], 'Accept-Encoding: gzip, deflate';
    is $http.<HTTP-message>.<header-field>.[3].<name>, 'Accept-Encoding';
    is $http.<HTTP-message>.<header-field>.[3].<value>.<codings>.[0], 'gzip';
    is $http.<HTTP-message>.<header-field>.[3].<value>.<codings>.[1], 'deflate';

    is $http.<HTTP-message>.<header-field>.[4], 'User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)';
    is $http.<HTTP-message>.<header-field>.[4].<name>, 'User-Agent';
    is $http.<HTTP-message>.<header-field>.[4].<value>, 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)';

    is $http.<HTTP-message>.<header-field>.[5], 'Connection: Keep-Alive';
    is $http.<HTTP-message>.<header-field>.[5].<name>, 'Connection';
    is $http.<HTTP-message>.<header-field>.[5].<value>, 'Keep-Alive';

}, 'Basic';



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
}, 'Zef.pm basic';



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
    my $content-length = $http.<HTTP-message>.<header-field>.list.first({ $_.<name> eq 'Content-Length' }).<value>;

    is $content-length, 5, 'Content-Length correct value';
    is $http.<HTTP-message>.<message-body>, 48092, "Report Number parsed from body";
}, 'P6C mock test report response';



done();
