use Zef;

class Zef::Extract does Pluggable {
    method extract($path, $extract-to, :&stdout = -> $o {$o.say}, :&stderr = -> $e {$e.say}) {
        die "Can't extract non-existent path: {$path}" unless $path.IO.e;
        die "Can't extract to non-existent path: {$extract-to}" unless $extract-to.IO.e || $extract-to.IO.mkdir;
        my $extractors = self.plugins.grep(*.extract-matcher($path));
        die "No extracting backend available" unless ?$extractors;

        $extractors[0].stdout.Supply.act(&stdout);
        $extractors[0].stderr.Supply.act(&stderr);

        my $got = $extractors[0].extract($path, $extract-to);

        $extractors[0].stdout.done;
        $extractors[0].stderr.done;

        die "something went wrong extracting {$path} to {$extract-to} with {$.plugins.join(',')}" unless $got;
        return $got;
    }
}
