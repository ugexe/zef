module Zef::Utils::SystemQuery {

    =begin pod

    =title module Zef::Utils::SystemQuery

    =subtitle Utility subroutines for resolving declarative logic based dependencies

    =head1 Synopsis

    =begin code :lang<raku>

        use Zef::Utils::SystemQuery;

        my @depends = (
            {
                "name" => {
                    "by-distro.name" => {
                        "mswin32" => "Windows::Dependency",
                        ""        => "NonWindows::Dependency"
                    },
                },
            },
        );

        my @resolved-depends := system-collapse(@depends);

        say @resolved-depends.raku;
        # [{:name("Windows::Dependency")},]    # on windows systems
        # [{:name("NonWindows::Dependency")},] # on non-windows systems

    =end code

    =head1 Description

    Provides facilities for resolving dependencies that use declarative logic.

    =head1 Subroutines

    =head2 sub system-collapse

        our sub system-collapse($data)

    Traverses an C<Array> or C<Hash> C<$data>, collapsing the blocks of declarative logic and returns the
    otherwise same data structure.

    Declarative logic current supports three main query forms:

        # by-env-exists.$FOO - selects "yes" key %*ENV{$FOO} exists, else the "no" key
        "by-env-exists.FOO" : {
            "yes" : "Env::Exists",
            "no"  : "Env::DoesNotExists"
        }

        # by-env.$FOO - selects the value of %*ENV{$FOO} as the key, else the "" key if there is no matching key
        "by-env.FOO" : {
            "SomeValue" : "Env::FOO::SomeValue",
            ""          : "Env::FOO::DefaultValue"
        }

        # by-[distro|kernel|raku|vm].$FOO - selects the value of e.g. $*DISTRO.name as the key, else the "" key if there is no matching key
        # where $FOO is e.g. $*DISTRO.^methods (or $*KERNEL.^methods, $*RAKU.^methods, $*VM.^methods)
        "by-distro.name" : {
            "macosx" : "OSX::Dependency",
            ""       : "NonOSX::Dependency"
        }

    Note that e.g. C<$*DISTRO.name> (and thus the C<by-[distro|kernel|raku|vm].$FOO> form) depends on potentially C<Raku> backend
    specific stuff -- for instance libuv based backends would have similar e.g. C<$*DISTRO> values, but on the JVM C<$*DISTRO.name>
    might return "linux" when MoarVM returns "debian". When using this query form you will want to test on multiple systems.

    =end pod


    our sub system-collapse($data) is export {
        return $data unless $data ~~ Hash|Array;

        my sub walk(@path, $idx, $query-source) {
            die "Attempting to find \$*{@path[0].uc}.{@path[1..*].join('.')}"
                if !$query-source.^can("{@path[$idx]}") && $idx < @path.elems;
            return $query-source."{@path[$idx]}"()
                if $idx+1 == @path.elems;
            return walk(@path, $idx+1, $query-source."{@path[$idx]}"());
        }

        my $return = $data.WHAT.new;

        for $data.keys -> $idx {
            given $idx {
                when /^'by-env-exists'/ {
                    my $key = $idx.split('.')[1];
                    my $value = %*ENV{$key}:exists ?? 'yes' !! 'no';
                    die "Unable to resolve path: {$idx} in \%*ENV\nhad: {$value}"
                        unless $data{$idx}{$value}:exists;
                    return system-collapse($data{$idx}{$value});
                }
                when /^'by-env'/ {
                    my $key = $idx.split('.')[1];
                    my $value = %*ENV{$key};
                    die "Unable to resolve path: {$idx} in \%*ENV\nhad: {$value // ''}"
                        unless defined($value) && ($data{$idx}{$value}:exists);
                    return system-collapse($data{$idx}{$value});
                }
                when /^'by-' (distro|kernel|perl|raku|vm)/ {
                    my $query-source = do given $/[0] {
                        when 'distro' { $*DISTRO }
                        when 'kernel' { $*KERNEL }
                        when 'perl'   { $*RAKU   }
                        when 'raku'   { $*RAKU   }
                        when 'vm'     { $*VM     }
                    }
                    my $path  = $idx.split('.');
                    my $value = walk($path, 1, $query-source).Str; # to stringify e.g. True
                    my $fkey  = ($data{$idx}{$value}:exists)
                        ?? $value
                        !! ($data{$idx}{''}:exists)
                            ?? ''
                            !! Any;

                    die "Unable to resolve path: {$path.cache[*-1].join('.')} in \$*DISTRO\nhad: {$value} ~~ {$value.WHAT.^name}"
                        if Any ~~ $fkey;
                    return system-collapse($data{$idx}{$fkey});
                }
                default {
                    my $val = system-collapse($data ~~ Array ?? $data[$idx] !! $data{$idx});
                    $return{$idx} = $val
                        if $return ~~ Hash;
                    $return.push($val)
                        if $return ~~ Array;

                }
            };
        }

        return $return;
    }
}
