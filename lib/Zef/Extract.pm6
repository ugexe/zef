use Zef;

class Zef::Extract does Pluggable {
    method extract($path, $extract-to, :&stdout = -> $o {$o.say}, :&stderr = -> $e {$e.say}) {
        die "Can't extract non-existent path: {$path}" unless $path.IO.e;
        die "Can't extract to non-existent path: {$extract-to}" unless $extract-to.IO.e || $extract-to.IO.mkdir;
        my $extractor = self.plugins.first(*.extract-matcher($path));
        die "No extracting backend available" unless ?$extractor;

        #$extractor.stdout.Supply.act(&stdout);
        #$extractor.stderr.Supply.act(&stderr);

        my $got = $extractor.extract($path, $extract-to);

        #$extractor.stdout.done;
        #$extractor.stderr.done;

        die "something went wrong extracting {$path} to {$extract-to} with {$.plugins.join(',')}" unless $got;
        return $got;
    }
}
