unit module Zef::Utils::SystemQuery;
use NativeCall;

sub follower(@path, $idx, $PTR) {
    die "Attempting to find \$*{@path[0].uc}.{@path[1..*].join('.')}"
        if !$PTR.^can("{@path[$idx]}") && $idx < @path.elems;
    return $PTR."{@path[$idx]}"()
        if $idx+1 == @path.elems;
    return follower(@path, $idx+1, $PTR."{@path[$idx]}"());
}

sub system-native-dep($*lib) is export {
    my $err;
    try {
        CATCH { default {
            $err = "Cannot locate $*lib"
                if $_.Str ~~ /^^'Cannot locate native library'/;
        } };
        my $x = sub :: is native(sub { $*lib }) {*};
        $x.();
    };
    $err;
}

sub system-collapse($data) is export {
    return $data
        if $data !~~ Hash && $data !~~ Array;
    my $return = $data.WHAT.new;
    for $data.keys -> $idx {
        given $idx {
            when /^'by-env-exists'/ {
                my $key = $idx.split('.')[1];
                my $value = %*ENV{$key}:exists ?? 'yes' !! 'no';
                return system-collapse($data{$idx}{$value}) if $data{$idx}{$value}:exists;
                die "Unable to resolve path: {$idx} in \%*ENV\nhad: {$value}";
            }
            when /^'by-env'/ {
                my $key = $idx.split('.')[1];
                my $value = %*ENV{$key};
                return system-collapse($data{$idx}{$value}) if defined $value and $data{$idx}{$value}:exists;
                die "Unable to resolve path: {$idx} in \%*ENV\nhad: {$value // ''}";
            }
            when /^'by-' (['distro'|'kernel'|'backend'])/ {
                my $PTR = $/[0] eq 'distro'
                    ?? $*DISTRO
                    !! $/[0] eq 'kernel'
                        ?? $*KERNEL
                        !! $*BACKEND;
                my $path  = $idx.split('.');
                my $value = follower($path, 1, $*DISTRO);
                my $fkey;

                if $value ~~ Version {
                    my @checks = $data{$idx}.keys\
                        .map({
                            my $suff = $_.substr(*-1);
                            %(
                                version  => Version.new($suff eq qw<+ ->.any ?? $_.substr(0, *-1) !! $_),
                                orig-key => $_,
                                ($suff eq qw<+ ->.any ?? suffix => $suff !! ()),
                            )
                        })\
                        .sort({ $^b<version> cmp $^a<version> });

                    for @checks -> $version {
                        next unless
                            $version<version> cmp $value ~~ Same ||
                            ($version<version> cmp $value ~~ Less && $version<suffix> eq '+') ||
                            ($version<version> cmp $value ~~ More && $version<suffix> eq '-');
                        $fkey = $version<orig-key>;
                        last;
                    }
                }
                else {
                    $fkey = ($data{$idx}{$value}:exists)
                        ?? $value
                        !! ($data{$idx}{''}:exists)
                            ?? ''
                            !! Any;
                }

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
