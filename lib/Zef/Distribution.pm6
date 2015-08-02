# todo: 
# 1) Allow creation of a Distribution with precompiled files only (no source).
# 2) Allow passing in the META hash itself instead of requiring it as an existing file.
# 3) ACCEPTS/cmp methods so we can easily compare Distribution objects.
# 4) Create interface for Hooks/ implementation; a generic implementation such that 
#       installing a module without a package manager still works  (i.e. no 
#       `does SomePackageManager::Builder`, as this requires SomePackageManager to be installed)
# 5) Turn Zef::Builder/Tester/Installer/Uninstaller into roles that can be added to this
#       Zef::Distribution object. For example: if we want to skip tests during a `install` 
#       we would not attach the testing role and instead just the Build/Install roles.
#       This will allow Hooks to not only hook into parts of the process, but also completely 
#       replace the default Builder role all together.
# 6) System 'logging' such that we can record the actions:
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
}
