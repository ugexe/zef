use Zef;
use Zef::Utils::FileSystem;

class Zef::Extract does Extractor does Pluggable {

    =begin pod

    =title class Zef::Extract

    =subtitle A configurable implementation of the Extractor interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Extract;

        # Setup with a single extractor backend
        my $extractor = Zef::Extract.new(
            backends => [
                { module => "Zef::Service::Shell::tar" },
            ],
        );

        # Save the content of $uri to $save-to
        my $tar-file   = $*CWD.add("zef-v0.9.4.tar.gz");
        my $candidate  = Candidate.new(uri => $tar-file);
        my $extract-to = $*CWD.add("my-extract-dir");

        # Show what files an archive contains
        say "About to extract the following paths:";
        say "\t{$_}" for $extractor.ls-files($candidate);

        # Extract the archive
        my $extracted-to = $extractor.extract($candidate, $extract-to);
        say $extracted-to ?? "Done" !! "Something went wrong...";

    =end code

    =head1 Description

    An C<Extractor> that uses 1 or more other C<Extractor> instances as backends. It abstracts the logic
    to do 'extract this path with the first backend that supports the given path'.

    =head1 Methods

    =head2 method extract-matcher

        method extract-matcher($path --> Bool:D) 

    Returns C<True> if any of the probeable C<self.plugins> know how to extract C<$path>.

    =head2 method extract

        method extract(Candidate $candi, IO() $extract-to, Supplier :$logger, Int :$timeout --> IO::Path)

    Extracts the files for C<$candi> (usually as C<$candi.uri>) to C<$extract-to>. If a backend fails to extract
    for some reason (such as going over its C<:$timeout>) the next matching backend will be used. Failure occurs
    when no backend was able to extract the C<$candi>.

    An optional C<:$logger> can be supplied to receive events about what is occuring.

    An optional C<:$timeout> can be passed to denote the number of seconds after which we'll assume failure.

    On success it returns the C<IO::Path> where the data was actually extracted to. On failure it returns C<Nil>.

    Note this differs from other 'Extractor' adapters C<method fetch> (i.e. the extractors this uses as backends) which
    take a C<Str $uri> as the first parameter, not a C<Candidate $candi>.

    =head2 method ls-files

        method ls-files(IO() $archive-file --> Array[Str])

    On success it returns an C<Array> of relative paths that are available to be extracted from C<$archive-file>.

    =end pod


    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    #| Returns true if any of the backends 'extract-matcher' understand the given uri/path
    method extract-matcher($path --> Bool:D) { return so self!extract-matcher($path) }

    #| Returns the backends that understand the given uri based on their extract-matcher result
    method !extract-matcher($path --> Array[Extractor]) {
        my @matching-backends = self.plugins.grep(*.extract-matcher($path));

        my Extractor @results = @matching-backends;
        return @results;
    }

    #| A helper method to deliver the 'missing backends' suggestions for extractors
    method !extractors($path --> Array[Extractor]) {
        my @extractors = self!extract-matcher($path).cache;

        unless +@extractors {
            my @report_enabled  = self.plugins.map(*.short-name);
            my @report_disabled = self.backends.map(*.<short-name>).grep({ $_ ~~ none(@report_enabled) });

            die "Enabled extracting backends [{@report_enabled}] don't understand $path\n"
            ~   "You may need to configure one of the following backends, or install its underlying software - [{@report_disabled}]";
        }

        my Extractor @results = @extractors;
        return @results;
    }

    #| Will return the first successful result while attempting to extract the given $candi.uri
    method extract(Candidate $candi, IO() $extract-to, Supplier :$logger, Int :$timeout --> IO::Path) {
        my $path := $candi.uri;
        die "Can't extract non-existent path: {$path}" unless $path.IO.e;
        die "Can't extract to non-existent path: {$extract-to}" unless $extract-to.e || $extract-to.mkdir;

        my $extractors = self!extractors($path).map(-> $extractor {
            if ?$logger {
                $logger.emit({ level => DEBUG, stage => EXTRACT, phase => START, candi => $candi, message => "Extracting with plugin: {$extractor.^name}" });
                $extractor.stdout.Supply.act: -> $out { $logger.emit({ level => VERBOSE, stage => EXTRACT, phase => LIVE, candi => $candi, message => $out }) }
                $extractor.stderr.Supply.act: -> $err { $logger.emit({ level => ERROR,   stage => EXTRACT, phase => LIVE, candi => $candi, message => $err }) }
            }

            my $out = lock-file-protect("{$extract-to}.lock", -> {
                my $todo    = start { try $extractor.extract($path, $extract-to) };
                my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
                await Promise.anyof: $todo, $time-up;
                $logger.emit({ level => DEBUG, stage => EXTRACT, phase => LIVE, candi => $candi, message => "Extracting $path timed out" })
                    if ?$logger && $time-up.so && $todo.not;
                $todo.so ?? $todo.result !! Nil
            });

            # really just saving $extractor for an error message later on. should do away with it later
            $extractor => $out;
        });

        # gnu tar on windows doesn't always work as I expect, so try another plugin if extraction fails
        my $extracted-to = $extractors.grep({
            $logger.emit({ level => WARN, stage => EXTRACT, phase => LIVE, candi => $candi, message => "Extracting with plugin {.key.^name} aborted." })
                if ?$logger && !(.value.defined && .value.IO.e);
            .value.defined && .value.IO.e;
        }).map(*.value).head;
        die "something went wrong extracting {$path} to {$extract-to} with {$.plugins.join(',')}" unless $extracted-to.IO.e;

        my IO::Path $result = $extracted-to.IO;
        return $result;
    }

    #| Will return the results first successful extraction, where the results are an array of strings, where
    #| each string is a relative path representing a file that can be extracted from the given $acandi.uri
    #| Note this differs from other 'Extract' adapters .extract() which take a $uri as the first
    #| parameter, not a $candi
    method ls-files($candi, :$logger --> Array[Str]) {
        my $path       := $candi.uri;
        my $extractors := self!extractors($path);
        my $name-paths := $extractors.map(*.ls-files($path)).first(*.defined).map(*.IO);
        my @files       = $name-paths.map({ .is-absolute ?? $path.child(.relative($path)).cleanup.relative($path) !! $_ });

        my Str @results = @files.map(*.Str);
        return @results;
    }
}
