use Zef;
use Zef::Utils::URI;

class Zef::Service::Shell::git does Probeable does Messenger {
    has $.scheme;

    method probe {
        state $probe = try { run('git', '--help', :!out, :!err).so };
    }

    method fetch-matcher($orig-url) {
        my $url = self!repo-url($orig-url);
        return $url.starts-with('git' | 'http' | 'ssh') && $url.ends-with('.git');
    }

    method extract-matcher($str) {
        return False unless $str.IO.d;
        my $proc = zrun('git', 'status', :!out, :!err, :cwd($str));
        $proc.so;
    }

    method fetch($url, IO() $save-as) {
        return self!clone(self!repo-url($url), $save-as) || self!pull($save-as);
    }

    method extract(IO() $repo-path, IO() $extract-to) {
        die "target repo directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $sha1 = self!rev-parse(self!fetch($repo-path)).head;
        die "target repo directory {$repo-path.absolute} failed to locate checkout revision"
            unless $sha1;

        my $checkout-to = $extract-to.child($sha1);
        die "target repo directory {$extract-to.absolute} does not exist and could not be created"
            unless ($checkout-to.e && $checkout-to.d) || mkdir($checkout-to);

        return self!checkout($repo-path, $checkout-to, $sha1);
    }

    method ls-files(IO() $repo-path) {
        die "target repo directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $passed;
        my $output = Buf.new;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', 'ls-tree', '-r', '--name-only', self!checkout-name($repo-path));
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-paths = $output.decode.lines;
        $passed ?? @extracted-paths.grep(*.defined) !! ();
    }

    method !clone($url, IO() $save-as) {
        die "target download directory {$save-as.absolute} does not exist and could not be created"
            unless $save-as.d || mkdir($save-as);

        my $passed;
        react {
            my $cwd := $save-as.parent;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', 'clone', $url, $save-as.basename, '--quiet');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        ($passed && $save-as.child('.git').d) ?? $save-as !! False;
    }

    method !pull(IO() $repo-path) {
        die "target download directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $passed;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', 'pull', '--quiet');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        $passed ?? $repo-path !! False;
    }

    method !fetch(IO() $repo-path) {
        die "target download directory {$repo-path.absolute} does not contain a .git/ folder"
            unless $repo-path.child('.git').d;

        my $passed;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', 'fetch', '--quiet');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        $passed ?? $repo-path !! False;
    }

    method !checkout(IO() $repo-path, IO() $extract-to, $target) {
        my $passed;
        react {
            my $cwd := $repo-path.absolute;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', '--work-tree', $extract-to, 'checkout', $target, '.');
            whenever $proc.stdout(:bin) { }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        $passed ?? $extract-to !! False;
    }

    method !rev-parse(IO() $save-as) {
        die "target repo directory {$save-as.absolute} does not contain a .git/ folder"
            unless $save-as.child('.git').d;

        my $passed;
        my $output = Buf.new;
        react {
            my $cwd := $save-as.absolute;
            my $ENV := %*ENV;
            my $proc = zrun-async('git', 'rev-parse', self!checkout-name($save-as));
            whenever $proc.stdout(:bin) { $output.append($_) }
            whenever $proc.stderr(:bin) { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my @extracted-refs = $output.decode.lines;
        $passed ?? @extracted-refs.grep(*.defined) !! ();
    }

    method !repo-url($url) {
        my $uri = uri($!scheme ?? $url.subst(/^\w+ '://'/, "{$!scheme}://") !! $url) || return False; #'
        ($uri.scheme // '') ~ '://' ~ ($uri.host // '') ~ ($uri.path // '').subst(/\@.*[\/|\@|\?|\#]?$/, '');
    }

    method !checkout-name($url) {
        my $uri      = uri($url) || return False;
        my $checkout = ($uri.path // '').match(/\@(.*)[\/|\@|\?|\#]?/)[0];
        return $checkout ?? $checkout.Str !! 'HEAD';
    }
}
