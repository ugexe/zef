use Zef::Utils::Depends;
use Zef::Utils::PathTools;
use Zef::ProcessManager;

# Provide functionality for precompiling modules
class Zef::Builder {
    has $.pm;
    has $.async;

    has %.meta;

    has $.path;
    has $.precomp-path;

    has @.libs;
    has @.includes is rw;

    submethod BUILD(IO::Path :$!path, IO::Path :$!precomp-path, :$!pm, :@!libs is copy, :@!includes, Bool :$!async) {
        %!meta  = %(from-json( $!path.IO.child('META.info').IO.slurp ))\
            or die "No META file found";
        $!precomp-path = $!path.child('blib') unless $!precomp-path;

        @!libs .= unshift: (@!libs || $!path.child('lib'))>>.IO>>.abspath>>.IO;
        @!libs .= push: $!path.child('lib');

        $!pm = !$!pm.defined ?? Zef::ProcessManager.new(:$!async)
                             !! $!pm.DEFINITE
                                ?? $!pm
                                !! ::($!pm).new;
    }

    # todo: lots of cleanup/refactoring
    method precomp(Bool :$force, :@targets) {
        @targets = @targets || $*VM.precomp-ext ~~ /moar/ ?? 'mbc' !! 'jar';

        # my $manifest  = from-json( %*CUSTOM_LIB<site>.IO.child('MANIFEST').IO.slurp );
        # NOTE: this may change
        # Currently treats relative paths as relative to the current repo's path ($path).
        # It may or may not be better to treat them as relative to the users CWD. We shall see.
        print "!!!> No META.info `provides` section. Skipping.\n" and next unless %!meta<provides>.values;
        print "===> Build directory: {$!precomp-path.abspath}\n";
        my @provides-abspaths = %!meta<provides>.values.map({ $_.IO.absolute($!path).IO });


        # Build the @dep chain for the %META.<provides> by parsing the 
        # use/require/need from the module source.
        my @deps = extract-deps( @provides-abspaths ).list;
        my @provides-as-deps = eager gather for @deps -> $dep-meta is rw {
            $dep-meta.<depends> = [$dep-meta.<depends>.list.map(-> $name { 
                %!meta.<provides>.list\
                    .grep({ $_.key eq $name })\
                    .map({ $_.value.IO.absolute($!path) });
            } )];

            $dep-meta.<name> = %!meta.<provides>.list\
                .map({ $_.value.IO.absolute($!path).IO })\
                .first({ $_ eq $dep-meta.<path>.IO.absolute($!path) });

            take $dep-meta;
        }


        my @targets-as-args  = @targets.map({   qqw/--target=$_/ });
        my @libs-as-args     = ($!precomp-path, @!libs).map({ qqw/-I$_/ });
        my @includes-as-args = @!includes.map({ qqw/-I$_/        });


        # @provides-as-deps is a partial META.info hash, so pass the $meta.<provides>
        # Note topological-sort with no arguments will sort the class's @projects (provides in this case)
        my @levels = Zef::Utils::Depends.new(projects => @provides-as-deps).topological-sort;


        my @curlfs;
        # Create the build order for the `provides`
        my @todo-processes = eager gather for @levels -> $level {
            my @process-levels;
            for $level.list -> $module-id {
                my $file = $module-id.IO.absolute($!path).IO;
                # Many tests are (incorrectly) written with the assumption the cwd is their projects base directory.
                my $file-rel = ?$file.IO.is-relative ?? $file.IO !! $file.IO.relative($!path);

                for @targets -> $target {
                    my $out = $!precomp-path.parent.child("{$file-rel}.{$target ~~ /mbc/ ?? 'moarvm' !! 'jar'}");

                    @process-levels.push: $!pm.create(
                        $*EXECUTABLE,
                        @libs-as-args,
                        @includes-as-args,
                        "--target=$target",
                        "--output=$out",
                        $file-rel,
                        :cwd($!path),
                        :id($file-rel)
                    );

                    @curlfs.push($out.IO.absolute($!path));
                }
            }

            take [@process-levels];
        }

        # todo: re-enable parallel building via :$async flag
        for @todo-processes -> $proc-level {
            mkdirs($_) for $proc-level.list.map({ $!precomp-path.parent.child($_.args[*-1].IO.parent) }).grep(!*.IO.e);
            my @promises = eager gather for $proc-level.list -> $proc {
                print "{$proc.file.IO.basename} {$proc.args.join(' ')}\n";
                take $proc.start;
            }
            await Promise.allof(@promises) if @promises;
        }


        return {
            ok           => ?$!pm.ok-all,
            precomp-path => IO::Path.new-from-absolute-path($!precomp-path.abspath, CWD => $!path), 
            path         => $!path,
            curlfs       => @curlfs.grep(*.IO.e).grep(*.IO.f), 
            sources      => %!meta<provides>.list,
            module       => %!meta<name>,
        }
    }
}
