use Zef::Phase::Getting;
use Zef::Utils;

use IO::Socket::SSL;
use JSON::Fast;


class Zef::Getter does Zef::Phase::Getting {
    multi method get(:$save-to is copy = $*TMPDIR, *@modules) {
        my @fetched;
        my @failed;

        for @modules -> $module {
            temp $save-to = $*SPEC.catdir($save-to, $module);
            my $data   = to-json({
                name => $module,
            });

            my $sock = IO::Socket::SSL.new(:host<zef.pm>, :port(443));
            $sock.send("POST /api/download HTTP/1.0\r\nConnection: close\r\nHost: zef.pm\r\nContent-Length: {$data.chars}\r\n\r\n$data\r\n");
            my $recv  = '';
            while my $r = $sock.recv { $recv ~= $r; }
            $recv = $recv.split("\r\n\r\n",2)[1];
            my $test = try from-json($recv);
            die $test<error> if $test<error>:exists;
            $recv = $recv.substr(0, *-2);
            my $mode  = 0o0644;
            try { mkdir $save-to } or fail "error: $_";
            try { 
                for @($recv.split("\r\n")) -> $path is copy, $enc is copy {
                    ($mode, $path) = $path.split(':', 2);
                    KEEP @fetched.push($module => $save-to);
                    UNDO @failed.push($module => False);

                    # Handle directory creation
                    my IO::Path $dir = $*SPEC.catdir($save-to, $path.IO.dirname).IO;
                    try { mkdir $dir } or fail "error: $_";

                    # Handle file creation
                    my $fh = $*SPEC.catpath('', $dir, $path.IO.basename).IO.open(:w);
                    say "encoding";
                    my $t1 = time;
                    my $dc = Zef::Utils.b64decode($enc);
                    my $t2 = time;
                    say "done encoding";
                    say "\t{$t2-$t1}";
                    $fh.write($dc) or fail "write error: $_";
                    $fh.close;
                    try $*SPEC.catpath('', $dir, $path.IO.basename).IO.chmod($mode.Int);
                }
                CATCH { default { "FAIL: $_".say; fail "Unable to unpack $module"; } }
            }
            say "Fetched";
        }

        return %(@fetched, @failed);
    }
}
