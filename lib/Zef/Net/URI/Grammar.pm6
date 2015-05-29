use Zef::Net::URI::Grammar::RFC3986;
use Zef::Net::URI::Grammar::RFC4234;

grammar Zef::Net::URI::Grammar {
    also does Zef::Net::URI::Grammar::RFC3986;
    also does Zef::Net::URI::Grammar::RFC4234;

    token TOP      { <URI-reference> }
    token TOP_URI  { <URI>           }
}
