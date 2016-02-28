use Zef;

class Zef::Extract does Pluggable {
    method extract($path, $extract-to, Supplier :$stdout, Supplier :$stderr) {
        die "Can't extract non-existent path: {$path}" unless $path.IO.e;
        die "Can't extract to non-existent path: {$extract-to}" unless $extract-to.IO.e || $extract-to.IO.mkdir;
        my $extractors := self.plugins.grep(*.extract-matcher($path)).cache;
        die "No extracting backend available" unless ?$extractors;

        my $got = first *.IO.e, gather for $extractors -> $ex {
            $ex.stdout.Supply.act: -> $out { ?$stdout ?? $stdout.emit($out) !! $*OUT.say($out) }
            $ex.stderr.Supply.act: -> $err { ?$stderr ?? $stderr.emit($err) !! $*ERR.say($err) }
            my $out = try $ex.extract($path, $extract-to);
            $ex.stdout.done;
            $ex.stderr.done;
            take $out;
        }

        die "something went wrong extracting {$path} to {$extract-to} with {$.plugins.join(',')}" unless $got;
        return $got;
    }
}
