unit module Zef::Utils::SystemQuery;

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
            when /^'by-' (distro|kernel|perl|vm)/ {
                my $query-source = do given $/[0] {
                    when 'distro' { $*DISTRO }
                    when 'kernel' { $*KERNEL }
                    when 'perl'   { $*PERL   }
                    when 'vm'     { $*VM     }
                }
                my $path  = $idx.split('.');
                my $value = walk($path, 1, $query-source);
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
