use Zef;
use Zef::Distribution::Local;

class Zef::Service::Shell::DistributionBuilder does Builder {

    =begin pod

    =title class Zef::Service::Shell::DistributionBuilder

    =subtitle A META6-supplied raku module based implementation of the Builder interface

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef;
        use Zef::Service::Shell::DistributionBuilder;

        my $builder = Zef::Service::Shell::DistributionBuilder.new;

        # Add logging if we want to see output
        my $stdout = Supplier.new;
        my $stderr = Supplier.new;
        $stdout.Supply.tap: { say $_ };
        $stderr.Supply.tap: { note $_ };

        # Assuming our current directory is a raku distribution with something like
        # `"builder" : "Distribution::Builder::MakeFromJSON"` in its META6.json
        #  and has no dependencies (or all dependencies already installed)...
        my $dist-to-build = Zef::Distribution::Local.new($*CWD);
        my Str @includes = $*CWD.absolute;
        my $built-ok = so $builder.build($dist-to-build, :@includes, :$stdout, :$stderr);
        say $built-ok ?? "OK" !! "Something went wrong";

    =end code

    =head1 Description

    C<Builder> class for handling local distributions that include a C<"builder" : "..."> in their C<META6.json>.
    For example C<"builder" : "Distribution::Builder::MakeFromJSON"> will spawn a process where it passes the
    module C<Distribution::Builder::MakeFromJSON> the path of the distribution and the parsed meta data (from which
    it may use other instructions from non-standard fields in the C<META6.json>).

    =head1 Methods

    =head2 method probe

        method probe(--> Bool:D)

    Returns C<True> if this module can successfully launch the C<raku> command (i.e. always returns C<True>).

    =head2 method build-matcher

        method build-matcher(Zef::Distribution::Local $dist --> Bool:D)

    Returns C<True> if this module knows how to test C<$uri>. This module always returns C<True> right now since
    it just uses the C<raku> command.

    =head2 method build

        method build(Zef::Distribution::Local $dist, Str :@includes, Supplier :$stdout, Supplier :$stderr --> Bool:D)

    Launches a process to invoke whatever module is in the C<builder> field of the C<$dist> META6.json while passing
    that module the meta data of C<$dist> it is to build (allowing non-spec keys to be used by such modules to allow
    consumers/authors to supply additional data). A C<Supplier> can be supplied as C<:$stdout> and C<:$stderr> to receive
    any output.

    See C<Distribution::Builder::MakeFromJSON> in the ecosystem for an example of such a C<builder>, and see C<Inline::Python>
    for an example of a distribution built using such a C<builder>.

    Returns C<True> if the C<raku> process spawned to run the build module exits 0.

    =end pod


    #| Return true always since it just requires launching another raku process
    method probe { True }

    #| Return true if this Builder understands the given meta data (has a 'builder' key) of the provided distribution
    method build-matcher(Zef::Distribution::Local $dist) { so $dist.builder }

    #| Run the build step of this distribution.
    method build(Zef::Distribution::Local $dist, Str :@includes, Supplier :$stdout, Supplier :$stderr --> Bool:D) {
        die "path does not exist: {$dist.path}" unless $dist.path.IO.e;

        # todo: remove this ( and corresponding code in Zef::Distribution.build-depends-specs ) in the near future
        # Always use the full name 'Distribution::Builder::MakeFromJSON', not 'MakeFromJSON'
        my $dist-builder-compat = "$dist.builder()" eq 'MakeFromJSON'
            ?? "Distribution::Builder::MakeFromJSON"
            !!  "$dist.builder()";

        my $tmp-meta-file = do given $*TMPDIR.child("zef-distribution-builder/") {
            my $dir = $_.child(Date.today);
            mkdir $dir;
            $dir = $dir.child("{time}-{$*PID}-{$*THREAD.id}");
            mkdir $dir;
            $dir.child('META6.json').absolute;
        }

        $tmp-meta-file.IO.spurt(Zef::to-json($dist.meta.hash), :close);

        my $cmd = "exit((require ::(q|$dist-builder-compat|)).new("
                ~ ":meta(Distribution::Path.new({$tmp-meta-file.IO.parent.absolute.raku}\.IO).meta.hash)"
                ~ ").build(q|$dist.path()|)"
                ~ '??0!!1)';

        my @exec = |($*EXECUTABLE.absolute, |@includes.grep(*.defined).map({ "-I{$_}" }), '-e', "$cmd");

        $stdout.emit("Command: {@exec.join(' ')}");

        my $ENV := %*ENV;
        my $passed;
        react {
            my $proc = Zef::zrun-async(@exec, :w);
            whenever $proc.stdout.lines { $stdout.emit($_) }
            whenever $proc.stderr.lines { $stderr.emit($_) }
            whenever $proc.start(:$ENV, :cwd($dist.path)) { $passed = $_.so }
        }
        return $passed;
    }
}
