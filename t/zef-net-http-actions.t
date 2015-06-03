use v6;
use Test;
plan 2;

use Zef::Net::HTTP::Grammar;
use Zef::Net::HTTP::Actions;


subtest {
    my $response = q{GET /http.html HTTP/1.1}
        ~ "\r\n" ~ q{Host: www.http.header.free.fr}
        ~ "\r\n" ~ q{Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg,}
        ~ "\r\n" ~ q{Accept-Language: Fr}
        ~ "\r\n" ~ q{Accept-Encoding: gzip; q=0.5, deflate}
        ~ "\r\n" ~ q{User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)}
        ~ "\r\n" ~ q{Connection: Keep-Alive}
        ~ "\r\n\r\n";
    my $actions = Zef::Net::HTTP::Actions.new;

    my $http = Zef::Net::HTTP::Grammar.parse($response, :$actions);
    my %header = $http.<HTTP-message>.<header-field>>>.made;

    is %header<Host>, 'www.http.header.free.fr';
    is %header<Accept>, [
        :range( [:type("image"), :subtype("gif")      ] ), 
        :range( [:type("image"), :subtype("x-xbitmap")] ), 
        :range( [:type("image"), :subtype("jpeg")     ] ), 
        :range( [:type("image"), :subtype("pjpeg")    ] ),
    ];
    is %header<Accept-Language>, 'Fr';
    is %header<Accept-Encoding>, [
        [:coding<gzip>, :weight<0.5> ], 
        [:coding<deflate>            ],
    ];
    is %header<User-Agent>, 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)';
    is %header<Connection>, 'Keep-Alive';
}, 'Header basics';


subtest {
    my $response = q{GET /http.html HTTP/1.1}
        ~ "\r\n" ~ q{Accept: audio/*;x1=x;x2=xx; q=0.2;ext=420, audio/basic}
        ~ "\r\n\r\n";
    my $actions = Zef::Net::HTTP::Actions.new;

    my $http = Zef::Net::HTTP::Grammar.parse($response, :$actions);
    my %header = $http.<HTTP-message>.<header-field>>>.made;

    is %header<Accept>.list.elems, 2, "Found both Accept header media types";
    is %header<Accept>, [
        [:range( [:type("audio"), :subtype("*"), :parameters([ :x1("x"), :x2("xx") ]) ] ), :weight("0.2"), :parameters([ :ext("420") ])],
        [:range( [:type("audio"), :subtype("basic")] )],
    ], 'Correctly distinguished media-type parameters, weight, and accept-parameters';
}, 'Header: multi level structure';


done();
