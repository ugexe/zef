use Zef::Phase::Getting;
use Zef::Utils::Base64;
use Zef::Utils::PathTools;
use Zef::Utils::HTTPClient;

our %path-map = %(
    [':' => '-']
);

# needs to be changed to return the absolute path to each *repo*, not every module file
class Zef::Getter does Zef::Phase::Getting {
    method get(:$save-to is copy = $*TMPDIR, *@modules) {
        my $ua = Zef::Utils::HTTPClient.new(auto-check => True);

        my @results = eager gather for @modules -> $module {
            temp $save-to = $*SPEC.catdir($save-to, $module.trans(%path-map));

            my $payload  = to-json({ name => $module });
            my $response = $ua.post('http://zef.pm/api/download', :$payload);
            my $data     = $response.body;
            my $mode    = 0o0644;

            try mkdirs($save-to);
            for @($data.substr(0, *-2).split("\r\n")) -> $path is copy, $enc is copy {
                ($mode, $path) = $path.split(':/', 2);
                my $save-to-file = $*SPEC.catpath('', $*SPEC.catdir($save-to, $path.IO.dirname), $path.IO.basename).IO;
                KEEP take { ok => 1, module => $module, file => $save-to-file.IO.path, path => $path }
                UNDO take { ok => 0, module => $module, path => $path, error => $_ }

                my $dir = $*SPEC.catdir($save-to, $path.IO.dirname).IO;
                try mkdirs($dir.IO.path);
                my $file    = $*SPEC.catpath('', $dir.IO.path, $path.IO.basename).IO;
                my $decoded = b64decode($enc);
                $file.spurt($decoded) or fail "write error: $_";
                try $file.chmod($mode.Int);
            }
        }

        return @results;
    }
}
