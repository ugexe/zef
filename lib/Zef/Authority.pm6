class Zef::Authority {

    has $.session-key;

    method login(:$username, :$password) {
        use IO::Socket::SSL;
        my $data = to-json({ username => $username, password => $password });
        my $sock = IO::Socket::SSL.new(:host<zef.pm>, :port(443));
        $sock.send("POST /login HTTP/1.0\r\nHost: zef.pm\r\nContent-Length: {$data.chars}\r\n\r\n{$data}");
        my %result = %(from-json($sock.recv.decode('UTF-8').split("\r\n\r\n")[1]));
        
        if %result<success> {
            say 'Login successful.';
            $.session-key = %result<newkey>;
        } 
        elsif %result<failure> {
            say "Login failed with error: {%result<reason>}";
            return False;
        } 
        else {
            say 'Unknown problem -';
            say %result.perl;
            return False;
        }

        return True;
    }

    method register(:$username, :$password) {
        use IO::Socket::SSL;
        my $data = to-json({ username => $username, password => $password });
        my $sock = IO::Socket::SSL.new(:host<zef.pm>, :port(443));
        $sock.send("POST /register HTTP/1.0\r\nHost: zef.pm\r\nContent-Length: {$data.chars}\r\n\r\n{$data}");
        my %result = %(from-json($sock.recv.decode('UTF-8').split("\r\n\r\n")[1]));
        
        if %result<success> {
            say 'Welcome to Zef.';
            $.session-key = %result<newkey>;
        } 
        elsif %result<failure> {
            say "Registration failed with error: {%result<reason>}";
            return False;
        } 
        else {
            say 'Unknown problem -';
            say %result.perl;
            return False;
        }

        return True;
    }

    method search(*@terms) {
        use IO::Socket::SSL;
        for @terms -> $term {
            my $data = to-json({ query => $term });
            my $sock = IO::Socket::SSL.new(:host<zef.pm>, :port(443));
            $sock.send("POST /search HTTP/1.0\r\nHost: zef.pm\r\nContent-Length: {$data.chars}\r\n\r\n{$data}");
            my @results = @(from-json($sock.recv.decode('UTF-8').split("\r\n\r\n")[1]));
            say "Results for $term";
            say "Package\tAuthor\tVersion";
            for @results -> %result {
                say "{%result<name>}\t{%result<owner>}\t{%result<version>}";
            }
        }
    }

    method push(*@targets, :$session-key, :@exclude?, :$force?) {
        require MIME::Base64;
        
        for @targets -> $target {
            my $data = '';
            my @paths = $target.dir;
            my @files;
            my @failures;

            while @paths.shift -> $path {
                next if $path ~~ @exclude.any;
                given $path.IO {
                    when :d { for .dir -> $io { @paths.push: $io } }
                    when :f { @files.push($_) }
                }            
            }

            FILES: for @files -> $path {
                my $buff = try { 
                        MIME::Base64.encode-str: $*SPEC.catdir('.', $path).IO.slurp;
                    } or try {
                        my $b = Buf.new;
                        my $f = $path.open(:r);
                        while !$f.eof { 
                            $b ~= $f.read(1024); 
                        }
                        $f.close;
                        MIME::Base64.encode($b);
                    } or fail "Failed to encode data";

                if $buff !~~ Str {
                    @failures.push($path);
                    last FILES unless $force;
                } 

                $data ~= "{$path}\r\n{$buff}\r\n";
            }

            if !$force && @failures {
                print "Failed to package the following files:\n\t";
                say @failures.join("\n\t");
                exit 1;
            } 

            my $metf = try {'META.info'.IO.slurp} \ 
                or try {'META6.json'.IO.slurp}    \ 
                or die "Couldn't find META6.json or META.info";

            my $json = to-json({ key => $session-key, data => $data, meta => %(from-json($metf)) });
            my $sock = IO::Socket::SSL.new(:host<zef.pm>, :port(443));
            $sock.send("POST /push HTTP/1.0\r\nHost: zef.pm\r\nContent-Length: {$json.chars}\r\n\r\n{$json}");
            my %result = %(from-json($sock.recv.decode('UTF-8').split("\r\n\r\n")[1]));
            
            if %result<version> {
                say "Successfully pushed version '{%result<version>}' to server";
            } 
            elsif %result<error> {
                say "Error pushing module to server: {%result<error>}";
                return False;
            } 
            else {
                say "Unknown error - {%result.perl}";
                return False;
            }

            return True;
        }        
    }
}