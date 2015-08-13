# todo: 
# 1) Allow creation of a Distribution with precompiled files only (no source).
# 2) Allow passing in the META hash itself instead of requiring it as an existing file.
# 3) ACCEPTS/cmp methods so we can easily compare Distribution objects.
# 4) System 'logging' such that we can record actions like:
#   * IO actions like mkdir, cd, etc
#   * Proc actions (shell/run)
#   such that we could theoretically generate a perl6 script that would mimick the function of 
#   a makefile (like ufo), allowing simple sans-package-manager installs.
class Zef::Distribution {
    has $.name;
    has $.authority;
    has $.version;

    has %.meta;

    has $.path;         # Where root path of the Distribution where a META is located
    has $.meta-path;    # Path to META file (META.info, META6.json)
    has $.source-path;  # These will help centralize the area we handle file paths
    has $.precomp-path; # to make handling windows fixes easier

    has @.includes;
    has @.perl6lib;

    method metainfo {self.hash}
    method hash {
        {
            :$!name,
            :auth($!authority),
            :ver($!version                   // '*'),
            :description(%!meta<description> //  ''),
            :depends(%!meta<depends>.list    //  []),
            :provides(%!meta<provides>.hash  //  {}),
            :files(%!meta<files>.list        //  []),
            :source-url(%!meta<source-url>   //  ''),
        }
    }

    submethod BUILD(IO::Path :$!path!, IO::Path :$!meta-path, :@!perl6lib,
        IO::Path :$!source-path, IO::Path :$!precomp-path, :@!includes) {
        
        $!meta-path = ($!path.child('META.info'), $!path.child('META6.json')).grep(*.IO.e).first(*.IO.f)
            unless $!meta-path;
        %!meta = %(from-json( $!path.IO.child('META.info').IO.slurp ))\
            or die "Distributions require a META file, but one was not found.";


        # Clean the `provides` paths. If we find an absolute path, assume that it is 
        # a mistake. Then turn it into a relative path now so further functionality
        # can can really assume a relative path.
        %!meta<provides>.hash.kv.grep({ $_.IO.is-absolute }).values\
            .map: -> $location is rw { $location = $!path.child($location).relative($!path) }

        # Set defaults for the location of the source files if needed by 
        # looking at the META provides and finding the longest common 
        # directory. This could be improved to allow multiple paths.

        unless $!source-path {
            die unless %!meta<provides>;
            my @p = %!meta<provides>.values\
                .map: { [$!path.IO.SPEC.splitdir($_.IO.parent).grep(*.so)] }
            my $wanted-path-index = first { not all(@p[*; $_]:exists) && [eq] @p[*; $_] }, 0..*;
            my $base = @p[0].[0..($wanted-path-index - 1)].first(*); 
            # for first path that contains source use:     ^ .reduce({ $^a.IO.child($^b)  });
            # which may be useful for detecting more complex lib paths

            $!source-path = $!path.child($base);
        }

        unless $!precomp-path {
            $!precomp-path = @!includes
                ?? @!includes.first(*.IO.e).IO
                !! $!path.child('blib').child($!source-path.IO.relative($!path).IO.relative);
        }

        $!name      = %!meta<name> or die 'META must provide a `name` field';
        $!authority = %!meta<auth> || "{%!meta<authority> || ''}:{%!meta<author> || ''}";
        $!version   = Version.new(%!meta<ver> || %!meta<version> || '*').Str;

        # bind these so they get updated in methods metainfo/hash
        %!meta<auth>    := $!authority;
        %!meta<version> := $!version;
    }


    method provides(Bool :$absolute) {
        my @p := gather for %.meta<provides>.pairs {
            my $name    := $_.key;
            my $pm-file := $_.value;
            $absolute
                ?? take $name => ($pm-file.IO.is-relative ?? $pm-file.IO.absolute($!path) !! $pm-file.IO.abspath)
                !! take $name => ($pm-file.IO.is-relative ?? $pm-file.IO !! $pm-file.IO.relative($!path));
        }
        @p.hash;
    }


    method is-installed(*@curlis is copy) {
        @curlis := @curlis ?? @curlis !! $.curlis;
        my $want-n := self.name or fail "A distribution must have a name";
        my $want-a := self.authority;
        my $want-v := Version.new(self.version).Str;

        gather for @curlis -> $curli {
            for $curli.candidates($want-n).list -> $have {
                my $have-n = $have<name> or next;
                my $have-a = $have<auth> || "{$have<authority> || ''}:{$have<author> || ''}";
                my $have-v = Version.new($have<ver> || $have<version> || '*').Str;
                next unless $have-n.lc eq $want-n.lc
                        ||  $have-a.lc eq $want-a.lc
                        ||  ($have-v.lc eq $want-v.lc || $want-v eq '*');
                take $curli;
            }
        }
    }


    method curlis {
        @*INC.grep( { .starts-with("inst#") } )\
            .map: { CompUnitRepo::Local::Installation.new(PARSE-INCLUDE-SPEC($_).[*-1]) };
    }

    method candidates(::CLASS:D:) { $.curlis>>.candidates($.name, :auth($.authority), :ver($.version)).grep(*) }

    method wanted(:$take-whatever = True) {
        return True if  $.version eq '*' && $take-whatever;
        return False if $.candidates.first({ $.VCOMPARE($_.<ver>.Str) ~~ any(Order::Same, Order::Less) });
        return True;
    }

    method VCOMPARE($other) {
        # TEMPORARY - $version.ACCEPTS() needs work
        sub CLEAN-VER($version is copy) {
            # v1.0 -> 1.0
            $version.subst-mutate(/^[v || V] '.'?/, '', :x(1));

            # 0.100.1 -> 0.10.0.1
            if $version ~~ /(0 ** 2..*)/ {
                $version.subst-mutate(/(0 ** 2..*)/, $/[0].Str.comb.join('.'), :g);
            }

            # 0.02 -> 0.0.2
            if $version ~~ /(0\d+)/ {
                $version.subst-mutate(/(0\d+)/, $/[0].Str.comb.join('.'), :g);
            }

            return $version;
        }

        my $want-ver = Version.new: CLEAN-VER($other);
        my $ver      = Version.new: $.version.Str;

        return Order::Same  if $ver eq $want-ver.Str;
        return Order::Less if $ver eq '*';

        # Version objects ACCEPTS do not seem to give a valid `cmp` result 
        # so this chops up version string in such a way that it ACCEPTS 
        # works as expected.
        if $ver.Str.chars > ($want-ver.Str.chars - ($want-ver.plus ?? 1 !! 0)) {
            my $leftovers = $ver.Str.substr($want-ver.Str.chars - 1).subst(/[\d || \w]/, '*', :g);
            $want-ver = Version.new: CLEAN-VER($want-ver.Str.substr(0, ($want-ver.plus ?? ($want-ver.Str.chars - 1) !! $want-ver.Str.chars)) ~ $leftovers ~ ($want-ver.plus ?? '+' !! ''));
            $want-ver = Version.new( CLEAN-VER($want-ver.Str.subst(/\.'*'/, '.0', :g)) ) unless $want-ver.plus;
        }
        elsif $ver.Str.chars < ($want-ver.Str.chars - ($want-ver.plus ?? 1 !! 0)) {
            my $leftovers = $want-ver.Str.substr($ver.Str.chars - 1, *-1).subst(/[\d || \w]/, $want-ver.plus ?? '*' !! 0);
            $ver = Version.new: CLEAN-VER($ver.Str ~ $leftovers);
        }

        return $ver cmp $want-ver;
    }
}
