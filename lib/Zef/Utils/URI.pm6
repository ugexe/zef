class Zef::Utils::URI {
    has $.is-relative;
    has $.match;

    has $.scheme;
    has $.host;
    has $.port;
    has $.user-info;
    has $.path;
    has $.query;
    has $.fragment;

    method CALL-ME($id) { try self.new($id) }

    my grammar URI {
        token URI-reference { <URI> || <relative-ref>                                   }
        token URI           { <scheme> ':' <heir-part> ['?' <query>]? ['#' <fragment>]? }
        token relative-ref  { <relative-part> ['?' <query>]? ['#' <fragment>]?          }
        token heir-part     {
            || '//' <authority> <path-abempty>
            || <path-absolute>
            || <path-noscheme>
            || <path-empty>
        }
        token relative-part {
            || '//' <authority> <path-abempty>
            || <path-absolute>
            || <path-noscheme>
            || <path-empty>
        }

        token scheme {
            <.alpha>
            [
            || <.alpha>
            || <.digit>
            || '+'
            || '-'
            || '.'
            ]*
        }

        token authority   { [<userinfo> '@']? <host> [':' <port>]? }
        token userinfo    { [<.unreserved> || <.pct-encoded> || <.sub-delims> || ':']*  }
        token host        { <.IP-literal> || <.IPv4address> || <.reg-name>              }
        token IP-literal  { '[' [<.IPv6address> || <.IPv6addrz> || <.IPvFuture>] ']'    }
        token IPv6addz    { <.IPv6address> '%25' <.ZoneID>    }
        token ZoneID      { [<.unreserved> || <.pct-encoded>]+ }
        token IPvFuture   { 'v' <.xdigit>+ '.' [<.unreserved> || <.sub-delims> || ':']+ }
        token IPv6address {
            ||                                      [<.h16>   ':'] ** 6 <.ls32>
            ||                                 '::' [<.h16>   ':'] ** 5 <.ls32>
            || [ <.h16>                     ]? '::' [<.h16>   ':'] ** 4 <.ls32>
            || [[<.h16> ':'] ** 0..1 <.h16> ]? '::' [<.h16>   ':'] ** 3 <.ls32>
            || [[<.h16> ':'] ** 0..2 <.h16> ]? '::' [<.h16>   ':'] ** 2 <.ls32>
            || [[<.h16> ':'] ** 0..3 <.h16> ]? '::'  <.h16>   ':'       <.ls32>
            || [[<.h16> ':'] ** 0..4 <.h16> ]? '::'                     <.ls32>
            || [[<.h16> ':'] ** 0..5 <.h16> ]? '::'  <.h16>
            || [[<.h16> ':'] ** 0..6 <.h16> ]? '::'
        }
        token h16  { <.xdigit> ** 1..4 }
        token ls32 { [<.h16> ':' <.h16>] || <.IPv4address> }
        token IPv4address { <.dec-octet> '.' <.dec-octet> '.' <.dec-octet> '.' <.decoctet> }
        token dec-octet {
            || <.digit>
            || [\x[31]..\x[39]] <.digit>
            || '1' <.digit> ** 2
            || '2'  [\x[30]..\x[34]] <.digit>
            || '25' [\x[30]..\x[35]]
        }
        token reg-name { [<.unreserved> || <.pct-encoded> || <.sub-delims>]* }
        token port     { <.digit>* }

        token path     {
            || <.path-abempty>
            || <.path-absolute>
            || <.path-noscheme>
            || <.path-rootless>
            || <.path-empty>
        }
        token path-abempty  { ['/' <.segment>]*                      }
        token path-absolute { '/' [<.segment-nz> ['/' <.segment>]*]? }
        token path-noscheme { <.segment-nz-nc> ['/' <.segment>]*     }
        token path-rootless { <.segment-nz> ['/' <.segment>]*        }
        token path-empty    { <.pchar> ** 0                          }
        token segment       { <.pchar>* }
        token segment-nz    { <.pchar>+ }
        token segment-nz-nc { [<.unreserved> || <.pct-encoded> || <.sub-delims>]+    }
        token pchar { <.unreserved> || <.pct-encoded> || <.sub-delims> || ':' || '@' }
        token query       { [<.pchar> || '/' || '?']*           }
        token fragment    { [<.pchar> || '/' || '?']*           }
        token pct-encoded { '%' <.xdigit> <.xdigit>             }
        token unreserved  { <.alpha> || <.digit> || < - . _ ~ > }
        token reserved    { <.gen-delims> || <.sub-delims>      }

        token gen-delims  { < : / ? # [ ] @ >         }
        token sub-delims  { < ! $ & ' ( ) * + , ; = > } # ' <- fixes syntax highlighting

    }

    my grammar URI::File is URI {
        token TOP { <file-URI> }

        token file-URI       { <scheme> ":" <heir-part> [ "?" <query> ]? }

        token scheme         { "file" }

        token heir-part      { "//" <auth-path> || <local-path> }

        token auth-path      { [ <auth> ]? <path-absolute> || <unc-path> || <windows-path> }

        token auth           { [ <userinfo> "@" ]? <host> }

        token local-path     { <path-absolute> || <windows-path> }

        token unc-path       { "//" "/"? <authority> <path-absolute> }

        token windows-path   { <drive-letter> <path-absolute> }
        token drive-letter   { <alpha> [ <drive-marker> ]? }
        token drive-marker   { ":" || "|" }
    }

    method new($id is copy) {
        if URI::File.parse($id.subst('\\','/',:g), :rule<file-URI>) -> $m {
            my $ap             = $m.<heir-part><auth-path>;
            my $volume         = $ap.<windows-path>.<drive-letter> ~ ':'; # what IO::SPEC::Win32 understands
            my $path           = ~($ap.<windows-path> // $ap.<path-absolute> // die "Could not parse path from: $id");
            my $host           = ~($ap.<host> // '');
            my $scheme         = ~$m.<scheme>;
            my $is-relative    = ?$path.IO.is-relative;
            # because `|` is sometimes used as a windows volume separator in a file-URI
            my $normalized-path = $is-relative ?? $path !! $*SPEC.join($volume // '', $path, '');
            self.bless( :match($m), :$is-relative, :$scheme, :$host, :path($normalized-path) );
        }
        elsif URI.parse($id, :rule<URI>) -> $m {
            my $heir = $m.<heir-part>;
            my $auth = $heir.<authority>;
            self.bless(
                match       => $m,
                is-relative => False,
                scheme      => ~($m.<scheme>          //  '').lc,
                host        => ~($auth.<host>         //  ''),
                port        =>  ($auth.<port>         // Int).Int,
                user-info   => ~($auth.<userinfo>     //  ''),
                path        => ~($heir.<path-abempty> // '/'),
                query       => ~($m.<query>           //  ''),
                fragment    => ~($m.<fragment>        //  ''),
            );
        }
        elsif URI.parse($id, :rule<relative-ref>) -> $m {
            self.bless(
                match       => $m,
                is-relative => True,
                scheme      => ~($m.<scheme>        // '').lc,
                path        => ~($m.<relative-part> || '/'),
                query       => ~($m.<query>         // ''),
                fragment    => ~($m.<fragment>      // ''),
            );
        }
        else {
            die "Cannot parse $id as an URI";
        }
    }
}

sub uri($str) is export { Zef::Utils::URI($str) }
