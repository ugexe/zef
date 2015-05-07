use Zef::Utils::Base64;
use Zef::Utils::HTTPClient;
use nqp;

class Zef::Authority {
    has $.session-key is rw;

    method login(:$username, :$password) {
        my $payload  = to-json({ username => $username, password => $password }) // fail "Bad JSON";
        my $response = Zef::Utils::HTTPClient.new.post("https://zef.pm/api/login", $payload);
        my %result   = try %(from-json($response.<body>));

        if %result<success> {
            $.session-key = %result<newkey> // fail "Session-key problem";
            return True;
        } 
        elsif %result<failure> {
            $*ERR = %result<reason>;
            return False;
        } 

        fail "Problem receiving data";
    }

    method register(:$username, :$password) {
        my $payload  = to-json({ username => $username, password => $password });
        my $response = Zef::Utils::HTTPClient.new.post("https://zef.pm/api/register", $payload);
        my %result  = try %(from-json($response.<body>));
        
        if %result<success> {
            $.session-key = %result<newkey> // fail "Session-key problem";            
            return %result;
        } 
        elsif %result<failure> {
            $*ERR = %result<reason>;
            return %result;
        } 

        fail "Problem receiving data";
    }

    method search(*@terms) {
        my @results := eager gather for @terms -> $term {
            my $payload  = to-json({ query => $term });
            my $response = Zef::Utils::HTTPClient.new.post("http://zef.pm/api/search", $payload);

            my $json = from-json($response.<body>);
            take $json unless $json ~~ [];
        }

        return @results;
    }

    method push(*@targets, :$session-key, :@exclude?, :$force?) {
        for @targets -> $target {
            my $payload = '';
            my @paths = $target.IO.dir;
            my @files;
            my @failures;

            while @paths.shift -> $path {
                next if $path ~~ any @exclude;
                given $path.IO {
                    when :d { for .dir -> $io { @paths.push: $io } }
                    when :f { @files.push($_) }
                }            
            }

            for @files -> $path {
                my $buff = try { 
                        Zef::Utils::Base64.new.b64encode($path.IO.slurp);
                    } // try {
                        my $b = Buf.new;
                        my $f = open $path, :r;
                        while !$f.eof { 
                            $b ~= $f.read(1024); 
                        }
                        $f.close;
                        Zef::Utils::Base64.new.b64encode($b);
                    } // fail "Failed to encode data: { $path }";

                if $buff !~~ Str {
                    @failures.push($path);
                    last unless $force;
                } 
                $payload ~= "{nqp::stat($path.Str, nqp::const::STAT_PLATFORM_MODE).base(8)}:{$path.Str.subst(/ ^ $target /, '')}\r\n{$buff}\r\n";
            }

            if !$force && @failures {
                print("Failed to package the following files:\n\t");
                warn @failures.join("\n\t");
            } 

            my $metf = try {'META.info'.IO.slurp} \ 
                // try {'META6.json'.IO.slurp}    \ 
                // fail "Couldn't find META6.json or META.info";
            my $json     = to-json({ key => $session-key, data => $payload, meta => %(from-json($metf)) });
            my $response = Zef::Utils::HTTPClient.new.post("https://zef.pm/api/push", $payload);
            my %result   = try %(from-json($response.<body>));
            
            if %result<error> {
                $*ERR = "Error pushing module to server: {%result<error>}";
                return False;
            } 
            else {
                $*ERR =  "Unknown error - Reply from server:\n{%result.perl}";
                return False;
            }

            return True;
        }        
    }
}

