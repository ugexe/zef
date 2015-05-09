use Zef::Phase::Getting;
use Zef::Utils::Base64;
use Zef::Utils::PathTools;

our %path-map = %(
    [':' => '-']
);

class Zef::Getter does Zef::Phase::Getting {

    method get(:$save-to is copy = $*TMPDIR, *@modules) {
        try require IO::Socket::SSL;

        my @results := eager gather for @modules -> $module {
            temp $save-to = $*SPEC.catdir($save-to, $module.trans(%path-map));
            my $data   = to-json({
                name => $module,
            });

            my $sock = ::('IO::Socket::SSL') ~~ Failure 
                ?? IO::Socket::INET.new(:host<zef.pm>, :port(80)) 
                !! ::('IO::Socket::SSL').new(:host<zef.pm>, :port(443));
            $sock.send("POST /api/download HTTP/1.0\r\nConnection: close\r\nHost: zef.pm\r\nContent-Length: {$data.chars}\r\n\r\n$data\r\n");
            my $recv  = '';
            while my $r = $sock.recv { $recv ~= $r; }
            $recv = $recv.split("\r\n\r\n",2)[1];
            my $test = try from-json($recv);
            say "Error: {$test<error>}" and next if $test<error>:exists;
            $recv = $recv.substr(0, *-2);
            my $mode  = 0o0644;
            try mkdirs($save-to);

            for @($recv.split("\r\n")) -> $path is copy, $enc is copy {
                ($mode, $path) = $path.split(':/', 2);
                KEEP take { ok => 1, module => $module, path => $path }
                UNDO take { ok => 0, module => $module, error => $_   }

                # Handle directory creation
                my $dir = $*SPEC.catdir($save-to, $path.IO.dirname).IO;
                try mkdirs($dir.IO.path);
                # Handle file creation
                my $fh = $*SPEC.catpath('', $dir.IO.path, $path.IO.basename).IO;
                my $dc = Zef::Utils::Base64.new.b64decode($enc);
                $fh.spurt($dc) or fail "write error: $_";
                try $fh.chmod($mode.Int);
            }
        }

        return @results;
    }
}
