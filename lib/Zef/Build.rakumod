use Zef:ver($?DISTRIBUTION.meta<version>):api($?DISTRIBUTION.meta<api>):auth($?DISTRIBUTION.meta<auth>);
use Zef::Distribution:ver(Zef.^ver):api(Zef.^api):auth(Zef.^auth);

class Zef::Build does Builder does Pluggable {

    =begin pod

    =title class Zef::Build

    =subtitle A configurable implementation of the Builder interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Build;
        use Zef::Distribution::Local;

        # Setup with a single builder backend
        my $builder = Zef::Build.new(
            backends => [
                { module => "Zef::Service::Shell::LegacyBuild" },
            ],
        );

        # Assuming our current directory is a raku distribution with a Build.rakumod file...
        my $dist-to-build = Zef::Distribution::Local.new($*CWD);
        my $candidate     = Candidate.new(dist => $dist-to-build);
        my $logger        = Supplier.new andthen *.Supply.tap: -> $m { say $m.<message> }

        my $build-ok = so all $builder.build($candidate, :$logger);
        say $build-ok ?? "Build OK" !! "Something went wrong...";

    =end code

    =head1 Description

    A C<Builder> that uses 1 or more other C<Builder> instances as backends. It abstracts the logic
    to do 'build this distribution with the first backend that supports the given distribution'.

    =head1 Methods

    =head2 method build-matcher

        method build-matcher(Zef::Distribution $dist --> Bool:D)

    Returns C<True> if any of the probeable C<self.plugins> know how to build C<$dist>.

    =head2 method build

        method build(Candidate $candi, Str :@includes, Supplier :$logger, Int :$timeout, :$meta --> Array[Bool])

    Builds the distribution for C<$candi>. For more info see C<Zef::Service::Shell::LegacyBuild> and C<Zef::Service::Shell::DistributionBuilder>
    since the build step process is coupled tightly to the backend used.

    An optional C<:$logger> can be supplied to receive events about what is occuring.

    An optional C<:$timeout> can be passed to denote the number of seconds after which we'll assume failure.

    Returns an C<Array> with some number of C<Bool> (which depends on the backend used). If there are no C<False> items
    in the returned C<Array> then we assume success.

    =end pod


    submethod TWEAK(|) {
        @ = self.plugins; # preload plugins
    }

    #| Returns true if any of the backends 'build-matcher' understand the given uri/path
    method build-matcher(Zef::Distribution $dist --> Bool:D) { return so self!build-matcher($dist) }

    #| Returns the backends that understand the given uri based on their build-matcher result
    method !build-matcher(Zef::Distribution $dist --> Array[Builder]) {
        my @matching-backends = self.plugins.grep(*.build-matcher($dist));

        my Builder @results = @matching-backends;
        return @results;
    }

    #| Build the given path using any provided @includes
    #| Will return results from the first Builder backend that supports the given $candi.dist (distribution)
    method build(Candidate $candi, Str :@includes, Supplier :$logger, Int :$timeout --> Array[Bool]) {
        my $dist := $candi.dist;
        die "Can't build non-existent path: {$dist.path}" unless $dist.path.IO.e;

        my $builder = self!build-matcher($dist).first(*.so);
        die "No building backend available" unless ?$builder;

        my $stdout = Supplier.new;
        my $stderr = Supplier.new;

        if ?$logger {
            $logger.emit({ level => DEBUG, stage => BUILD, phase => START, candi => $candi, message => "Building with plugin: {$builder.^name}" });
            $stdout.Supply.grep(*.defined).act: -> $out { $logger.emit({ level => VERBOSE, stage => BUILD, phase => LIVE, candi => $candi, message => $out }) }
            $stderr.Supply.grep(*.defined).act: -> $err { $logger.emit({ level => ERROR,   stage => BUILD, phase => LIVE, candi => $candi, message => $err }) }
        }

        my $todo    = start { try $builder.build($dist, :@includes, :$stdout, :$stderr) };
        my $time-up = ($timeout ?? Promise.in($timeout) !! Promise.new);
        await Promise.anyof: $todo, $time-up;
        $logger.emit({ level => DEBUG, stage => BUILD, phase => LIVE, candi => $candi, message => "Building {$dist.path} timed out" })
            if ?$logger && $time-up.so && $todo.not;

        $stdout.done();
        $stderr.done();

        my Bool @results = $todo.so ?? $todo.result !! False;
        return @results;
    }
}
