use v6;
use Zef::Net::HTTP::Client;
try require Base64;

use Test;
plan 2;


ENTER {
    try { IO::Socket::INET.new(:host<httpbin.org>, :port(80)) } or do {
        print("1..0 ok - # Skip: No internet connection available? Test requires http://httpbin.org:80\n");
        return;
    }
    try { ::("Base64") ~~ Failure } or do {
        print("1..0 ok - # Skip: Please install the `Base64` module to use authorization\n");
        return;
    }
}


subtest {
    my $url = "http://httpbin.org";
    my $ua  = Zef::Net::HTTP::Client.new(:auto-check);

    # Status code
    {
        is $ua.post($url ~ '/status/200').status-code, 200, "Status 200";
        dies-ok { $ua.post($url ~ '/status/400').status-code }, "auto-check + bad status dies";
    }
    
    # Basic auth OK
    {
        temp $url = 'http://un:pw@httpbin.org';
        is $ua.get($url ~ '/basic-auth/un/pw').status-code, 200, "Basic auth";
    }

    # Basic auth FAIL
    {
        dies-ok { $ua.get($url ~ '/basic-auth/un/pw') }, "Fail basic auth and die. auto-check => True";

        temp $ua.auto-check = False;
        nok $ua.get($url ~ '/basic-auth/unx/pwx').status-code, "Fail basic auth and live. auto-check => False";
    }
}, "HTTP auth";


subtest {
    unless Zef::Net::HTTP::Client.new.transporter.dialer.?can-ssl {
        print("ok 2 - # Skip: Can't do SSL. Is IO::Socket::SSL available?\n");
        return;
    }

    my $url = "https://httpbin.org";
    my $ua  = Zef::Net::HTTP::Client.new(:auto-check);

    # Status code
    {
        is $ua.post($url ~ '/status/200').status-code, 200, "Status 200";
        dies-ok { $ua.post($url ~ '/status/400').status-code }, "auto-check + bad status dies";
    }

    # Basic auth OK
    {
        temp $url = 'https://un:pw@httpbin.org';
        is $ua.get($url ~ '/basic-auth/un/pw').status-code, 200, "Basic auth";
    }

    # Basic auth FAIL    
    {
        dies-ok { $ua.get($url ~ '/basic-auth/un/pw') }, "Fail basic auth and die. auto-check => True";

        temp $ua.auto-check = False;
        nok $ua.get($url ~ '/basic-auth/unx/pwx').status-code, "Fail basic auth and live. auto-check => True";
    }
}, "HTTPS auth";
