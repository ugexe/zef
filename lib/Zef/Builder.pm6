use Zef::Utils::Depends;
use Zef::Utils::PathTools;


# Provide functionality for precompiling modules
class Zef::Builder {
    # todo: lots of cleanup/refactoring
    method precomp(*@repos is copy, :$save-to is copy, Bool :$force) {
        # my $manifest  = from-json( %*CUSTOM_LIB<site>.IO.child('MANIFEST').IO.slurp );

        my @results = eager gather for @repos -> $path {
            my %meta  = %(from-json( $path.IO.child('META.info').IO.slurp ));


            # NOTE: this may change
            # Currently treats relative paths as relative to the current repo's path ($path).
            # It may or may not be better to treat them as relative to the users CWD. We shall see.
            temp $save-to = $save-to 
                ?? ($save-to.IO.is-absolute ?? $save-to.IO !! $save-to.IO.absolute($path).IO) 
                !! $path.IO;
            print "===> Build directory: {$save-to.absolute}\n";


            # Determine the paths where the sources are located, where the pre-compiled 
            # code should go, and what $INC should include before pre-compiling.


            my @libs = %meta<provides>.list\
                .grep({ $_.value.IO.absolute($path).IO.f })\
                .map({ ($*SPEC.splitdir($_.value.IO.dirname).[0].IO // $*SPEC.curdir).IO.absolute($path) })\
                .unique\
                .map({ CompUnitRepo::Local::File.new($_).Str });

            state @blibs.push($_) for @libs.map({  
                my $blib = $_.IO.relative($path).IO\
                    .parent.IO\
                    .child('blib').IO\
                    .child('lib').IO\
                    .absolute($save-to);
                CompUnitRepo::Local::File.new( $blib ).Str;
            });

            my $INC  := @blibs, @libs, @*INC;
            my @files = %meta<provides>.list.map({ $_.value.IO.absolute($path).IO.path });

            print "!!!> No files found. META.info `provides` section incorrect?" and next unless @files;

            # Build the @dep chain for the %META.<provides> by parsing the 
            # use/require/need from the module source.
            my @provides-as-deps = eager gather for @(extract-deps( @files ).list) -> $info is rw {
                $info.<depends> = [$info.<depends>.list.map(-> $name { 
                    %meta.<provides>.first({ $_.key eq $name }).value 
                } )];

                $info.<name>    = %meta.<provides>.list.first({ 
                    $_.value.IO.absolute($path).IO.path eq $info.<path>.IO.absolute($path)
                }).value;

                take $info;
            }


            # @provides-as-deps is a partial META.info hash, so pass the $meta.<provides>
            # Note topological-sort with no arguments will sort the class's @projects (provides in this case)
            my @levels   = Zef::Utils::Depends.new(projects => @provides-as-deps).topological-sort;


            # Create the build order for the `provides`
            my @compiled = eager gather for @levels -> $level {
                for $level.list -> $module-id {
                    # Workaround for non-default precomp-path 
                    # i.e. $out = /blib/lib/Name.pm6.ext instead of /lib/Name.pm6.ext
                    # CompUnit was not designed to be subclassed, so this is kinda ugly.
                    my $cu = CompUnit.new( $module-id.IO.absolute($path) ) but role { 
                        has $!has-precomp = False;
                        has $.build-output is rw;
                        has $.precomp-path is rw;

                        method BUILDALL(|) {
                            my $return = callsame;
                            $!precomp-path := pp();
                            return $return;
                        }

                        method precomp($out, |c) {
                            mkdirs($out.IO.dirname);
                            $!precomp-path = $out;
                            $!has-precomp  = callwith($out, |c);
                        }

                        sub pp() is rw { # 'precomp-path'
                            my $storage;
                            Proxy.new: FETCH => method ()   { $storage.IO.absolute if ?$storage },
                                       STORE => method ($p) { $storage = $p };
                        }
                    }
                    

                    # Relative and absolute file paths of where to *save* compiled ouput.
                    my $new-id-rel = 'blib'.IO.child($module-id.IO.dirname)\
                                              .child("{$module-id.IO.basename}.{$*VM.precomp-ext}").IO;

                    $new-id-rel = $new-id-rel.relative if $new-id-rel.is-absolute; # todo: delete? leftovers?

                    # relative to '$save-to', not relative to the repo source ($path)
                    my $new-id-absolute = $new-id-rel.IO.absolute($save-to).IO;

                    # todo: .build-output should really be a Channel/Supply to let the client
                    # tap/receieve the output instead of just printing it (like Zef::Test)
                    my $status = try ?$cu.precomp($new-id-absolute, :$INC, :$force);
                    $cu.build-output  = "[{$module-id}] {'.' x 42 - $module-id.chars} ";
                    my $output-rest   = $status ?? "ok: {$cu.precomp-path.IO.relative($save-to)}" !! "FAILED";
                    $cu.build-output ~= $output-rest;
                    print $cu.build-output ~ "\n";

                    take $cu;
                }
            }

            # subclassing CompUnit seems to get screw when calling .new on a module 
            # that augments core functionality (Utils::PathTools and augment IO::Path?)
            # so we will use this structure for now instead of a custom CompUnit extension
            take {  
                ok           => ?(@compiled.grep({ ?$_.has-precomp }).elems == %meta<provides>.list.elems),
                precomp-path => @blibs[0], 
                path         => $path, 
                curlfs       => @compiled, 
                sources      => %meta<provides>.list,
                module       => %meta<name>,
            }
        }

        return @results;
    }
}
