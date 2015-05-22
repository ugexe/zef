use v6;
use Zef::Utils::HTTPClient;
plan 2;
use Test;


ENTER {
    try { IO::Socket::INET.new(:host<httpbin.org>, :port(80)) } or do {
        print("ok - # Skip: No internet connection available? Test requires http://httpbin.org:80\n");
        return;
    }
}


subtest {
    my $url = "http://httpbin.org";
    my $ua  = Zef::Utils::HTTPClient.new(auto-check => True);

    # Status code
    {
        is $ua.post($url ~ '/status/200').status-code, 200, "Status 200";
        dies-ok { $ua.post($url ~ '/status/400').status-code }, "auto-check + bad status dies";
    }
    
    # Basic auth OK
    {
        temp $ua.user = 'un';
        temp $ua.pass = 'pw';
        is $ua.get($url ~ '/basic-auth/un/pw').status-code, 200, "Basic auth";
    }

    # Basic auth FAIL    
    {
        dies-ok { $ua.get($url ~ '/basic-auth/un/pw') }, "Fail basic auth and die. auto-check => True";

        temp $ua.auto-check = False;
        nok $ua.get($url ~ '/basic-auth/unx/pwx').status-code, "Fail basic auth and live. auto-check => True";
    }
}, "HTTP";


subtest {
    unless Zef::Utils::HTTPClient.new.can-ssl {
        print("ok 2 - # Skip: Can't do SSL. Is IO::Socket::SSL available?\n");
        return;
    }

    my $url = "https://httpbin.org";
    my $ua  = Zef::Utils::HTTPClient.new(auto-check => True);

    # Status code
    {
        is $ua.post($url ~ '/status/200').status-code, 200, "Status 200";
        dies-ok { $ua.post($url ~ '/status/400').status-code }, "auto-check + bad status dies";
    }

    # Basic auth OK
    {
        temp $ua.user = 'un';
        temp $ua.pass = 'pw';
        is $ua.get($url ~ '/basic-auth/un/pw').status-code, 200, "Basic auth";
    }

    # Basic auth FAIL    
    {
        dies-ok { $ua.get($url ~ '/basic-auth/un/pw') }, "Fail basic auth and die. auto-check => True";

        temp $ua.auto-check = False;
        nok $ua.get($url ~ '/basic-auth/unx/pwx').status-code, "Fail basic auth and live. auto-check => True";
    }
}, "HTTPS";