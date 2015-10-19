unit module Zef::Utils::HTTP;

method parse-url($s) is export {
  my ($scheme, $host, $uri, $qs, $port, $auth);
  my $index1  = $s.index('://');
  my $index2  = $s.index('/', $index1 + 3) || $s.chars;
  $scheme     = $s.substr(0, $index1);
  $host     = $s.substr($index1 + 3, $index2 - $index1 - 3);
  ($uri, $qs) = ($s.substr($scheme.chars + $host.chars + 3) || '/').split('?', 2);

  $port = (grep * ~~ /^\d+$/, @($host.split(':')[*-1], ($scheme.lc eq 'https' ?? 443 !! 80)))[0];
  $auth = $host.index('@') ?? $host.split('@')[0] !! '';
  $host = $host.substr($auth.chars + ($auth ne '' ?? 2 !! 1), *-($port.chars + 2)) if $port !~~ any(80, 443) && $host.index(':');

  return {
    scheme => $scheme,
    host   => $host,
    uri    => $uri,
    qs     => $qs,
    port   => $port,
    auth   => $auth,
  };
}
