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

    submethod BUILD(:$!url) {
        $!grammar = Zef::Net::URI::Grammar.parse($!url) if $!url;

        if $!grammar {
            $!scheme    = ~($!grammar.<URI-reference>.<URI>.<scheme>                           //  '').lc;
            $!host      = ~($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<host>     //  '');
            $!port      =  ($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<port>     // Int).Int;
            $!user-info = ~($!grammar.<URI-reference>.<URI>.<heir-part>.<authority>.<userinfo> //  '');
            $!path      = ~$!grammar.<URI-reference>.<URI>.<heir-part>.<path-abempty> || '/';
        }
    }

    method Str {
        return $!grammar.Str;
    }
}