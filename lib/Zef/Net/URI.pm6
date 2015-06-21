use Zef::Net::HTTP;
use Zef::Net::URI::Grammar;

class Zef::Net::URI does HTTP::URI {
    has $.grammar;
    has $.url;
    has $.scheme;
    has $.user-info;
    has $.host;
    has $.port;
    has $.query;
    has $.fragment;
    has $.location;
    has $.path;
    has $.is-relative;

    # todo: allow construction from a relative URI if a base URI is passed in
    submethod BUILD(:$!url) {
        $!grammar = Zef::Net::URI::Grammar.parse($!url) if $!url;

        if $!grammar {
            if $!grammar.<URI-reference>.<URI> -> $g {
                    $!scheme    = ~($g.<scheme>                           //  '').lc;
                    $!host      = ~($g.<heir-part>.<authority>.<host>     //  '');
                    $!port      =  ($g.<heir-part>.<authority>.<port>     // Int).Int;
                    $!user-info = ~($g.<heir-part>.<authority>.<userinfo> //  '');
                    $!path      = ~($g.<heir-part>.<path-abempty>         || '/');
            }
            elsif $!grammar.<URI-reference>.<relative-ref> -> $g {
                    $!is-relative = True;

                    $!scheme    = ~($g.<scheme>        //  '').lc;
                    $!path      = ~($g.<relative-part> || '/');
            }
        }
    }

    method Str {
        return $!grammar.Str;
    }

    method rel2abs(HTTP::URI:D: $base-url) {
        return unless self.is-relative;

        my $abs-url = $base-url ~ (self.path.starts-with('/') ?? '' !! '/') ~ self.path;
        return Zef::Net::URI.new(url => $abs-url);
    }
}