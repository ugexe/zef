use Zef;
use Zef::Utils::FileSystem;

class Zef::Service::TAP does Tester {

    =begin pod

    =title class Zef::Service::TAP

    =subtitle A TAP module based implementation of the Tester interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::TAP;

        my $tap = Zef::Service::TAP.new;

        # Add logging if we want to see output
        my $stdout = Supplier.new;
        my $stderr = Supplier.new;
        $stdout.Supply.tap: { say $_ };
        $stderr.Supply.tap: { note $_ };

        # Assuming our current directory is a raku distribution
        # with no dependencies or all dependencies already installed...
        my $dist-to-test = $*CWD;
        my Str @includes = $*CWD.absolute;
        my $passed = so $tap.test($dist-to-test, :@includes, :$stdout, :$stderr);
        say $passed ?? "PASS" !! "FAIL";

    =end code

    =head1 Description

    C<Tester> class for handling path based URIs ending in .rakutest / .t6 / .t using the raku C<TAP> module.

    You probably never want to use this unless its indirectly through C<Zef::Test>;
    handling files and spawning processes will generally be easier using core language functionality. This
    class exists to provide the means for fetching a file using the C<Tester> interfaces that the e.g. Test/prove
    adapters use.

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully load the C<TAP> module.

    =head2 method test-matcher

        method test-matcher(Str() $uri --> Bool:D)

    Returns C<True> if this module knows how to test C<$uri>, which it decides based on if C<$uri> exists
    on local file system.

    =head2 method test

        method test(IO() $path, Str :@includes, Supplier :$stdout, Supplier :$stderr --> Bool:D)

    Test the files ending in C<.rakutest> C<.t6> or C<.t> in the C<t/> directory of the given C<$path> using the
    provided C<@includes> (e.g. C</foo/bar> or C<inst#/foo/bar>) via the C<TAP> raku module. A C<Supplier> can be
    supplied as C<:$stdout> and C<:$stderr> to receive any output.

    Returns C<True> if there were no failed tests and no errors according to C<TAP>.

    =end pod

    my Lock $probe-lock = Lock.new;
    my Bool $probe-cache;

    #| Return true if the `TAP` raku module is available
    method probe(--> Bool:D) {
        $probe-lock.protect: {
            return $probe-cache if $probe-cache.defined;
            my $probe = self!has-correct-tap-version && (try require ::('TAP')) !~~ Nil;
            return $probe-cache = $probe;
        }
    }

    method !has-correct-tap-version(--> Bool:D) {
        # 0.3.1 has fixed support for :err and added support for :output
        return so $*REPO.resolve(CompUnit::DependencySpecification.new(
            short-name      => 'TAP',
            version-matcher => '0.3.5+',
        ));
    }

    #| Return true if this Tester understands the given uri/path
    method test-matcher(Str() $uri --> Bool:D) { return $uri.IO.e }

    #| Test the given paths t/ directory using any provided @includes
    method test(IO() $path, Str :@includes, Supplier :$stdout, Supplier :$stderr --> Bool:D) {
        die "path does not exist: {$path}" unless $path.e;

        my $test-path = $path.child('t');
        return True unless $test-path.e;
        my @test-files = grep *.extension eq any('rakutest', 't', 't6'),
            list-paths($test-path.absolute, :f, :!d, :r).sort;
        return True unless +@test-files;

        my $result = try {
            require ::('TAP');
            my @incdirs  = $path.absolute, |@includes;
            my @handlers = ::("TAP::Harness::SourceHandler::Raku").new(:@incdirs);
            my $parser   = ::("TAP::Harness").new(:@handlers);
            my $promise  = $parser.run(
                @test-files.map(*.relative($path)),
                :cwd($path),
                :out($stdout),
                :err($stderr),
            );
            $promise.result;
        }

        my $passed = $result.failed == 0 && not $result.errors ?? True !! False;
        return $passed;
    }
}
