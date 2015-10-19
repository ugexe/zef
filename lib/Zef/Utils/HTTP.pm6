unit module Zef::Utils::HTTP;

method parse-url($s) is export {
    my $index1  = $s.index('://');
    my $index2  = $s.index('/', $index1 + 3) || $s.chars;
    my ($scheme, $host, $uri, $qs, $port, $auth) = (
      $s.substr(0, $index1),
      $s.substr($index1 + 3, $index2 - $index1 - 3),
      ($s.substr($index2) || '/').split('?', 2).Slip,
    );

    $port = (grep * ~~ /^\d+$/, @($host.split(':')[*-1], ($scheme.lc eq 'https' ?? 443 !! 80)))[0];
    $auth = $host.index('@') ?? $host.split('@')[0] !! '';
    $host = $host.substr($auth.chars + ($auth ne '' ?? 2 !! 1), *-($port.chars + 2)) if $port !~~ any(80, 443) && $host.index(':');

    return { :$scheme, :$host, :$uri, :$qs, :$port, :$auth };
}
