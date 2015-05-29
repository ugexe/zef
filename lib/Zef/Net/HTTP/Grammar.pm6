use Zef::Net::HTTP::Grammar::Extensions;
use Zef::Net::HTTP::Grammar::RFC1035;
use Zef::Net::HTTP::Grammar::RFC3066;
use Zef::Net::HTTP::Grammar::RFC4647;
use Zef::Net::HTTP::Grammar::RFC5322;
use Zef::Net::HTTP::Grammar::RFC5646;
use Zef::Net::HTTP::Grammar::RFC6265;
use Zef::Net::HTTP::Grammar::RFC6854;
use Zef::Net::HTTP::Grammar::RFC7230;
use Zef::Net::HTTP::Grammar::RFC7231;
use Zef::Net::HTTP::Grammar::RFC7232;
use Zef::Net::HTTP::Grammar::RFC7233;
use Zef::Net::HTTP::Grammar::RFC7234;
use Zef::Net::HTTP::Grammar::RFC7235;
use Zef::Net::URI::Grammar::RFC3986;
use Zef::Net::URI::Grammar::RFC4234;

grammar Zef::Net::HTTP::Grammar {
    also does Zef::Net::HTTP::Grammar::Extensions;
    also does Zef::Net::HTTP::Grammar::RFC1035;
    also does Zef::Net::HTTP::Grammar::RFC3066;
    also does Zef::Net::HTTP::Grammar::RFC4647;
    also does Zef::Net::HTTP::Grammar::RFC5322;
    also does Zef::Net::HTTP::Grammar::RFC5646;
    also does Zef::Net::HTTP::Grammar::RFC6265;
    also does Zef::Net::HTTP::Grammar::RFC6854;
    also does Zef::Net::HTTP::Grammar::RFC7230;
    also does Zef::Net::HTTP::Grammar::RFC7231;
    also does Zef::Net::HTTP::Grammar::RFC7232;
    also does Zef::Net::HTTP::Grammar::RFC7233;
    also does Zef::Net::HTTP::Grammar::RFC7234;
    also does Zef::Net::HTTP::Grammar::RFC7235;
    also does Zef::Net::URI::Grammar::RFC3986;
    also does Zef::Net::URI::Grammar::RFC4234;

    token TOP        { <HTTP-message> }
    token TOP-header { <HTTP-header>  }
} 