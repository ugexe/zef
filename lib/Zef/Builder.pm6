use Zef::Utils::Depends;
use Zef::Utils::PathTools;
use Zef::ProcessManager;

# Provide functionality for precompiling modules
class Zef::Builder {
    has $.pm;
    has $.async;
    has $.promise;

    has %.meta;

    has $.path;
    has $.precomp-path;

    has @.libs;
    has @.includes is rw;

    has @.targets;
    has @.curlfs;

    has @.sources; # temporary
    has $.module;  # temporary
    method hash {  # temporary
        %(ok => $.passes(), nok => $.failures(), module => $!module, curlfs => @!curlfs);
    }

    submethod BUILD(IO::Path :$!path, IO::Path :$!precomp-path, :$!pm, 
        :@!libs is copy, :@!includes, :@!targets, Bool :$!async) {
        
        %!meta = %(from-json( $!path.IO.child('META.info').IO.slurp ))\
            or die "No META file found";

        @!sources := %!meta<provides>.list; # temporary
        $!module  := %!meta<name>;          # temporary


        @!targets = @!targets || $*VM.precomp-ext ~~ /moar/ ?? 'mbc' !! 'jar';
        $!precomp-path = $!path.child('blib') unless $!precomp-path;

        @!libs .= unshift: (@!libs || $!path.child('lib'))>>.IO>>.abspath>>.IO;
        @!libs .= push: $!path.child('lib');

        my @provides-abspaths = %!meta<provides>.values.map({ $_.IO.absolute($!path).IO });
        # Build the @dep chain for the %META.<provides> by parsing the 
        # use/require/need from the module source.
        my @deps = extract-deps( @provides-abspaths ).list;
        my @provides-as-deps = eager gather for @deps -> $dep-meta is rw {
            $dep-meta.<depends> = [$dep-meta.<depends>.list.map(-> $name { 
                %!meta.<provides>.list\
                    .first({ $_.key eq $name })\
                    .map({ $_.value.IO.absolute($!path) });
            } )];

            $dep-meta.<name> = %!meta.<provides>.list\
                .map({ $_.value.IO.absolute($!path).IO })\
                .first({ $_.IO.ACCEPTS($dep-meta.<path>.IO.absolute($!path)) });

            take $dep-meta;
        }


        my @libs-as-args     = ($!precomp-path.child('lib'), @!libs).map({ qqw/-I$_/ });
        my @includes-as-args = @!includes.map({ qqw/-I$_/ });


        # @provides-as-deps is a partial META.info hash, so pass the $meta.<provides>
        # Note topological-sort with no arguments will sort the class's @projects (provides in this case)
        my @levels = Zef::Utils::Depends.new(projects => @provides-as-deps).topological-sort;


        # Create the build order for the `provides`
        my @todo-processes = eager gather for @levels -> $level {
            my $pm-level = Zef::ProcessManager.new(:$!async);

            for $level.list -> $module-id {
                my $file = $module-id.IO.absolute($!path).IO;
                # Many tests are (incorrectly) written with the assumption the cwd is their projects base directory.
                my $file-rel = ?$file.IO.is-relative ?? $file.IO !! $file.IO.relative($!path);

                for @!targets -> $target {
                    my $out = $!precomp-path.child("{$file-rel}.{$target ~~ /mbc/ ?? 'moarvm' !! 'jar'}");

                    $pm-level.create(
                        $*EXECUTABLE,
                        @libs-as-args,
                        @includes-as-args,
                        "--target=$target",
                        "--output=$out",
                        $file-rel,
                        :cwd($!path),
                        :id($file-rel)
                    );

                    @!curlfs.push($out.IO.is-absolute ?? $out !! $out.IO.absolute($!path));
                }
            }

            $!pm.push: $pm-level;
        }
    }

    method tap(&code) { $!pm>>.tap-all(&code) }

    method ok { ?all($!pm>>.ok-all) }

    method nok { ?$.ok() ?? False !! True }

    method passes {
        $!pm>>.processes.grep(*.ok.so)>>.id;
    }

    method failures {
        $!pm>>.processes.grep(*.ok.not)>>.id;
    }


    method start(:$p6flags) {
        print "!!!> No META.info `provides` section. Skipping.\n" and next unless %!meta<provides>.values;
        print "===> Build directory: {$!precomp-path.abspath}\n";

        my $p = Promise.new;

        if $!pm.list.elems {
            $p.keep(1);
            for $!pm.list -> $g {
                $p = $p.then({
                    $g.list>>.processes\
                        .map({ $!precomp-path.child($_.args[*-1].IO.parent) })\
                        .grep(!*.IO.d)\
                        .map({ mkdirs($_) });
                    await Promise.allof( $g.start-all );
                });
            }
        }
        else {
            $p.keep(1);
        }

        $!promise = $p;
    }
}
