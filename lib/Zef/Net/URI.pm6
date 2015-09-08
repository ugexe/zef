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
        $!grammar := Zef::Net::URI::Grammar.parse($!url) if $!url;

        if $!grammar.<URI-reference> -> $uri-ref {
            if $uri-ref.<URI> -> $g {
                    $!scheme    := ~($g.<scheme>                           //  '').lc;
                    $!host      := ~($g.<heir-part>.<authority>.<host>     //  '');
                    $!port      :=  ($g.<heir-part>.<authority>.<port>     // Int).Int;
                    $!user-info := ~($g.<heir-part>.<authority>.<userinfo> //  '');
                    $!path      := ~($g.<heir-part>.<path-abempty>         // '/');
                    $!query     :=  ~$g.<query> if ?$g.<query>;
            }
            elsif $uri-ref.<relative-ref> -> $g {
                    $!is-relative = True;

                    $!scheme    := ~($g.<scheme>        //  '').lc;
                    $!path      := ~($g.<relative-part> || '/');
                    $!query     :=  ~$g.<query> if ?$g.<query>;
            }
        }
    }

    method Str { $!grammar.Str }

    method absolute(HTTP::URI:D: $base = '') {
        self.is-relative
            ?? Zef::Net::URI.new( :uri($base ~ (self.path.starts-with('/') ?? '' !! '/') ~ self.path) )
            !! self;
    }

    method child(HTTP::URI:D: $child) {
        Zef::Net::URI.new(:url(~self.Str ~ (self.Str.ends-with('/') ?? '' !! '/') ~ $child));
    }
}