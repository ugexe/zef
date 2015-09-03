use Zef::Utils::Base64;
use Test;
plan 2;

subtest {
    my $encoder = Zef::Utils::Base64.new;
    is $encoder.b64encode(""), '', 'Encoding the empty string';
    is $encoder.b64encode("A"), 'QQ==', 'Encoding "A"';
    is $encoder.b64encode("Ab"), 'QWI=', 'Encoding "Ab"';
    is $encoder.b64encode("Abc"), 'QWJj', 'Encoding "Abc"';
    is $encoder.b64encode("Abcd"), 'QWJjZA==', 'Encoding "Abcd"';
    is $encoder.b64encode("Perl"), 'UGVybA==', 'Encoding "Perl"';
    is $encoder.b64encode("Perl6"), 'UGVybDY=', 'Encoding "Perl6"';
    is $encoder.b64encode("Another test!"), 'QW5vdGhlciB0ZXN0IQ==', 'Encoding "Another test!"';
    is $encoder.b64encode("username:thisisnotmypassword"), 'dXNlcm5hbWU6dGhpc2lzbm90bXlwYXNzd29yZA==', 'Encoding "username:thisisnotmypassword"';
    is $encoder.b64encode(Buf.new(0)), 'AA==', 'encode Test on NULL/0 byte';
    is $encoder.b64encode(Buf.new(1)), 'AQ==', 'encode Test on byte value 1';
    is $encoder.b64encode(Buf.new(255)), '/w==', 'encode Test on byte value 255';
}, 'Encode';

subtest {
    my $decoder = Zef::Utils::Base64.new;
    is $decoder.b64decode("").decode, '', 'decoding the empty string';
    is $decoder.b64decode("QQ==").decode, 'A', 'decoding "A"';
    is $decoder.b64decode("QWI=").decode, 'Ab', 'decoding "Ab"';
    is $decoder.b64decode('QWJj').decode, "Abc", 'decoding "Abc"';
    is $decoder.b64decode('QWJjZA==').decode, "Abcd", 'decoding "Abcd"';
    is $decoder.b64decode('UGVybA==').decode, "Perl", 'decoding "Perl"';
    is $decoder.b64decode('UGVybDY=').decode, "Perl6", 'decoding "Perl6"';
    is $decoder.b64decode("UGVy\nbDY=").decode, "Perl6", 'decoding "Perl6 with invalid b64 character"';
    is $decoder.b64decode('QW5vdGhlciB0ZXN0IQ==').decode, "Another test!", 'decoding "Another test!"';
    is $decoder.b64decode('dXNlcm5hbWU6dGhpc2lzbm90bXlwYXNzd29yZA==').decode, "username:thisisnotmypassword", 'decoding "username:thisisnotmypassword"';
    is-deeply $decoder.b64decode('AA=='), Buf.new(0), 'decode Test on NULL/0 byte';
    is-deeply $decoder.b64decode('AQ=='), Buf.new(1), 'decode Test on byte value 1';
    is-deeply $decoder.b64decode('/w=='), Buf.new(255), 'decode Test on byte value 255';
}, 'Decode';
