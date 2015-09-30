use Zef::Distribution;

class Zef::Distribution::Local does Zef::Distribution {
    has $.path;         # Where root path of the Distribution where a META is located
    has $.meta-path;    # Path to META file (META.info, META6.json)
    has $.source-path;  # These will help centralize the area we handle file paths
    has $.precomp-path; # to make handling windows fixes easier
    has %!hash;

    # blib/lib, lib. Passed in via -I
    # Only uses relative file paths and expects the cwd to reflect this.
    # Reason: name mangling on windows trying to pass absolute paths (mangled)
    has @.includes is rw;


    # /some/dependency/blib/lib, /some/dependency/lib ...
    # These will be set in PERL6LIB when built/tested/installed.
    # Uses absolute paths, as this is intended to be used to point
    # at possibly not-yet-installed-but-built packages (such that its
    # possible to bail out of a multi-package install if something fails
    # without having anything actually installed leftover)
    has @.perl6lib is rw;

    submethod BUILD(IO::Path :$!path!, IO::Path :$!meta-path, :@!perl6lib,
        IO::Path :$!source-path, IO::Path :$!precomp-path, :@!includes) {
        @!includes = @!includes.grep(*.so);
        @!perl6lib = @!perl6lib.grep(*.so);

        $!meta-path = ($!path.child('META.info'), $!path.child('META6.json'))\
            .grep(*.IO.e).cache.first(*.IO.f) unless $!meta-path;
        %!hash = %(from-json( $!meta-path.IO.slurp.cache ))\
            or die "Distributions require a META file, but one was not found.";

        # Clean the `provides` paths. If we find an absolute path, assume that it is 
        # a mistake. Then turn it into a relative path now so further functionality
        # can can really assume a relative path.
        %!hash<provides>.hash.kv.grep({ $_.IO.is-absolute }).values\
            .map: -> $location is rw { $location = $!path.child($location).relative($!path) }

        # Set defaults for the location of the source files if needed by 
        # looking at the META provides and finding the longest common 
        # directory. This could be improved to allow multiple paths.

        unless $!source-path {
            die "No provides section." unless %!hash<provides>; # ??
            my @p = %!hash<provides>.values\
                .map: { [$!path.IO.SPEC.splitdir($_.IO.parent).grep(*.so)] }

            my @keep-parts = eager gather for 0..@p.cache.map({ $_.cache.end }).min -> $i {
                my @check = @p.cache.map({ $_.[$i]; }).cache;
                my $elems = @check.unique.elems;
                last if @check.unique.elems !== 1;
                take @check[0];
            }
            my $base = @keep-parts[0]; # $*SPEC.catdir(@keep-parts);
            $base = '.' if $base.IO.f && !$base.IO.d;
            $!source-path = $!path.child($base);
        }

        unless $!precomp-path {
            $!precomp-path = @!includes.grep(*.so).elems
                ?? @!includes.first(*.?IO.e).IO
                !! $!path.child('blib').child($!source-path.IO.relative($!path).IO.relative);
        }

        $!name      = %!hash<name> or die 'META must provide a `name` field';
        $!authority = AUTHS2CS(|%!hash);
        $!version   = Version.new(%!hash<ver> || %!hash<version> || '*').Str;

        # bind these so they get updated in methods metainfo/hash
        %!hash<auth>    := $!authority;
        %!hash<version> := $!version;
    }

    method meta {
        {
            :$!name,
            :auth($!authority),
            :ver($!version                           // '*'),
            :description(%!hash<description>         //  ''),
            :depends(%!hash<depends>.grep(*.so).cache //  []),
            :provides(%!hash<provides>.hash          //  {}),
            :files(%!hash<files>.grep(*.so).cache     //  []),
            :source-url(%!hash<source-url>           //  ''),
        }
    }

    method content(*@keys) {
        my $resource = @keys[*-1];
        my $wanted   = @keys[0..*-2].reduce(-> $n1 is rw, $n2 {
            once $n1 = self.meta{$n1};
            $n1{$n2}
        });
        die "Can't find requested meta file key {@keys[*-1]}" unless $wanted eq $resource;

        my $abspath = $resource.IO.is-absolute ?? ~$resource.IO !! ~$resource.IO.absolute($.path).IO;
        my $io = IO::Path.new-from-absolute-path($abspath);

        die "Can't find resource with path: {$io}" unless $io.IO.e && $io.IO.f;

        $io.slurp;
    }

    method provides(Bool :$absolute) {
        my $p := gather for %.meta<provides>.pairs {
            my $name    := $_.key;
            my $pm-file := $_.value;
            $absolute
                ?? take $name => ($pm-file.IO.is-relative ?? $pm-file.IO.absolute($!path) !! $pm-file.IO.abspath)
                !! take $name => ($pm-file.IO.is-relative ?? $pm-file.IO !! $pm-file.IO.relative($!path));
        }
        $p.hash;
    }

    method candidates(::CLASS:D: :$version) {
        my %opts;
        %opts<authority> = $.authority if $.authority;
        flat $.curlis.map: {.candidates($.name, :auth($.authority), :ver($version // '*')).grep(*)}
    }
    method curlis {
        @*INC.grep( { .starts-with("inst#") } )\
            .map: { CompUnitRepo::Local::Installation.new(PARSE-INCLUDE-SPEC($_).[*-1]) };
    }
}

sub AUTHS2CS(*%fields) {
    return unless %fields && %fields.keys;

    if %fields<auth> -> $cs {
        # return value if <auth> is valid. otherwise we will move on and guess
        return $cs if %fields<auth> ~~ /.+ ':' .+/;

        # $cs exists, but wasn't valid. if $author is ok, assume it is authority (git:, cpan:)
        if %fields<author> -> $author {
            return "{$cs}:{$author}" if $cs ne $author;
        }

        # Same as above, but switching author and authority
        if %fields<authority> -> $authority {
            return "{$authority}:{$cs}" if $cs ne $authority;
        }

        # if we reach here that means `auth` has an invalid value
        # and we could not guess what its meant to be. maybe abort here?
    }

    # if author or authority contain a ':', assume the author is mistaken and meant it as auth
    if %fields<authority> -> $authority {
        return $authority if $authority ~~ /.+ ':' .+/;
    }

    if %fields<author> -> $author {
        return $author    if $author ~~ /.+ ':' .+/;
    }

    return %fields<authority author>.join(':') if %fields<authority author>.all;
}