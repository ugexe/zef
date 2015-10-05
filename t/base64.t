use Base64;

use Test;
plan 2;

subtest {
    is encode64(""), '', 'Encoding the empty string';
    is encode64("A"), 'QQ==', 'Encoding "A"';
    is encode64("Ab"), 'QWI=', 'Encoding "Ab"';
    is encode64("Abc"), 'QWJj', 'Encoding "Abc"';
    is encode64("Abcd"), 'QWJjZA==', 'Encoding "Abcd"';
    is encode64("Perl"), 'UGVybA==', 'Encoding "Perl"';
    is encode64("Perl6"), 'UGVybDY=', 'Encoding "Perl6"';
    is encode64("Another test!"), 'QW5vdGhlciB0ZXN0IQ==', 'Encoding "Another test!"';
    is encode64("username:thisisnotmypassword"), 'dXNlcm5hbWU6dGhpc2lzbm90bXlwYXNzd29yZA==', 'Encoding "username:thisisnotmypassword"';
    is encode64(Buf.new(0)), 'AA==', 'encode Test on NULL/0 byte';
    is encode64(Buf.new(1)), 'AQ==', 'encode Test on byte value 1';
    is encode64(Buf.new(255)), '/w==', 'encode Test on byte value 255';
}, 'Encode';

subtest {
    is decode64("").decode, '', 'decoding the empty string';
    is decode64("QQ==").decode, 'A', 'decoding "A"';
    is decode64("QWI=").decode, 'Ab', 'decoding "Ab"';
    is decode64('QWJj').decode, "Abc", 'decoding "Abc"';
    is decode64('QWJjZA==').decode, "Abcd", 'decoding "Abcd"';
    is decode64('UGVybA==').decode, "Perl", 'decoding "Perl"';
    is decode64('UGVybDY=').decode, "Perl6", 'decoding "Perl6"';
    is decode64("UGVy\nbDY=").decode, "Perl6", 'decoding "Perl6 with invalid b64 character"';
    is decode64('QW5vdGhlciB0ZXN0IQ==').decode, "Another test!", 'decoding "Another test!"';
    is decode64('dXNlcm5hbWU6dGhpc2lzbm90bXlwYXNzd29yZA==').decode, "username:thisisnotmypassword", 'decoding "username:thisisnotmypassword"';
    is-deeply decode64('AA=='), Buf.new(0), 'decode Test on NULL/0 byte';
    is-deeply decode64('AQ=='), Buf.new(1), 'decode Test on byte value 1';
    is-deeply decode64('/w=='), Buf.new(255), 'decode Test on byte value 255';
}, 'Decode';
