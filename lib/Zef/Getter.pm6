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

    multi method get(:$save-to = "$*TMPDIR.path/{time}", *@modules) {
        my @fetched;
        for @modules -> $module {
            next if @fetched.grep($module);
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
            mkdir $save-to;
            for @($recv.split("\r\n")) -> $file, $enc {
                mkdir $*SPEC.catdir($save-to, $file.IO.dirname) unless $file.IO.dirname.IO.e;
                my $fh = $*SPEC.catpath('', $save-to, $file).IO.open(:w);
                my $dc = MIME::Base64.decode($enc);
                $fh.write($dc);
                $fh.close;

                KEEP @fetched.push($file);
            }
        }

        return @fetched;
    }
}
