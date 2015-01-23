use Zef::Phase::Getting;
use JSON::Tiny;
use IO::Socket::SSL;
use MIME::Base64;

class Zef::Getter does Zef::Phase::Getting {

    has @.plugins;
    has $.sock;

    # TODO: load plugins if .does or .isa matches
    # so our code doesnt look like modules are
    # reloaded for every phase.
    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            self does ::($p) if do { require ::($p); ::($p).does(Zef::Phase::Getting) };
        }
        $!sock = IO::Socket::SSL.new(:host<zef.pm>, :port(443));
    }

    multi method get(*@modules) {
        for @modules -> $module {
            my $tmpdir = "{$*TMPDIR.path}/{time}";
            my $data   = to-json({
              name => $module,
            });
            my $recv   = '';
            my $buf;
            $!sock.send("POST /api/download HTTP/1.0\r\nConnection: close\r\nHost: zef.pm\r\nContent-Length: {$data.chars}\r\n\r\n$data\r\n");
            while $buf = $!sock.recv { 
              $recv ~= $buf.decode('UTF-8');  
            }
            $recv  = $recv.split("\r\n\r\n",2)[1].substr(0, *-2);
            mkdir $tmpdir;
            for @($recv.split("\r\n")) -> $file, $enc {
              mkdir $tmpdir ~ $file.IO.dirname;
              my $fh = open $tmpdir ~ $file, :w;
              my $dc = MIME::Base64.decode($enc);
              $fh.write($dc);
              $fh.close;
            }
            say 'path: ' ~ $tmpdir;
        }
    }
}
