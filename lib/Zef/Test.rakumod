use Zef;

class Zef::Test does Tester does Pluggable {

    =begin pod

    =title class Zef::Test

    =subtitle A configurable implementation of the Tester interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Test;
        use Zef::Distribution::Local;

        # Setup with a single tester backend
        my $tester = Zef::Test.new(
            backends => [
                { module  => "Zef::Service::Shell::prove" },
            ],
        );

        # Assuming our current directory is a raku distribution...
        my $dist-to-test = Zef::Distribution::Local.new($*CWD);
        my $candidate    = Candidate.new(dist => $dist-to-test);
        my $logger       = Supplier.new andthen *.Supply.tap: -> $m { say $m.<message> }

        # ...test the distribution using the first available backend
        my $passed = so all $tester.test($candidate, :$logger);
        say $passed ?? "PASS" !! "FAIL";

    =end code

    =head1 Description

    A C<Tester> class that uses 1 or more other C<Tester> instances as backends. It abstracts the logic
    to do 'test this path with the first backend that supports the given path'.

    =head1 Methods

    =head2 method test-matcher

        method test-matcher($path --> Bool:D)

    Returns C<True> if any of the probeable C<self.plugins> know how to test C<$path>.

    =head2 method test

        method test(Candidate $candi, Str :@includes, Supplier :$logger, Int :$timeout --> Array[Bool])

    Tests the files for C<$candi> (usually locally extracted files from C<$candi.dist> in the C<t/> directory with an extension
    of C<.rakutest> C<.t6> or C<.t>) using the provided C<@includes> (e.g. C</foo/bar> or C<inst#/foo/bar>. It will use
    the first matching backend, and will not attempt to use a different backend on failure (like e.g. C<Zef::Fetch>) since
    failing test are not unexpected.

    An optional C<:$logger> can be supplied to receive events about what is occurring.

    An optional C<:$timeout> can be passed to denote the number of seconds after which we'll assume failure.

    Returns an C<Array> with some number of C<Bool> (which depends on the backend used). If there are no C<False> items
    in the returned C<Array> then we assume success.

    =end pod


    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    #| Returns true if any of the backends 'test-matcher' understand the given uri/path
    method test-matcher($path --> Bool:D) { return so self!test-matcher($path) }

    #| Returns the backends that understand the given uri based on their test-matcher result
    method !test-matcher($path --> Array[Tester]) {
        my @matching-backends = self.plugins.grep(*.test-matcher($path));

        my Tester @results = @matching-backends;
        return @results;
    }

    #| Test the given path using any provided @includes,
    #| Will return results from the first Tester backend that supports the given path (via $candi.dist.path)
    method test(Candidate $candi, Str :@includes, Supplier :$logger, Int :$timeout --> Array[Bool]) {
        my $path := $candi.dist.path;
        die "Can't test non-existent path: {$path}" unless $path.IO.e;

        my $testers := self!test-matcher($path).cache;

        unless +$testers {
            my @report_enabled  = self.plugins.map(*.short-name);
            my @report_disabled = self.backends.map(*.<short-name>).grep({ $_ ~~ none(@report_enabled) });

            die "Enabled testing backends [{@report_enabled}] don't understand $path\n"
            ~   "You may need to configure one of the following backends, or install its underlying software - [{@report_disabled}]";
        }

        my $tester = $testers.head;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => TEST, phase => START, candi => $candi, message => "Testing with plugin: {$tester.^name}" });
            $tester.stdout.Supply.grep(*.defined).act: -> $out is copy { $logger.emit({ level => VERBOSE, stage => TEST, phase => LIVE, candi => $candi, message => $out }) }
            $tester.stderr.Supply.grep(*.defined).act: -> $err is copy { $logger.emit({ level => ERROR,   stage => TEST, phase => LIVE, candi => $candi, message => $err }) }
        }

        my $todo    = start { try $tester.test($path, :@includes) };
        my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
        await Promise.anyof: $todo, $time-up;
        $logger.emit({ level => DEBUG, stage => TEST, phase => LIVE, message => "Testing $path timed out" })
            if ?$logger && $time-up.so && $todo.not;

        my Bool @results = $todo.so ?? $todo.result !! False;
        return @results;
    }
}
