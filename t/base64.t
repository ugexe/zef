use Base64;

use Test;
plan 5;

subtest {
    is encode-base64(""), '', 'Encoding the empty string';
    is encode-base64("A"), 'QQ==', 'Encoding "A"';
    is encode-base64("Ab"), 'QWI=', 'Encoding "Ab"';
    is encode-base64("Abc"), 'QWJj', 'Encoding "Abc"';
    is encode-base64("Abcd"), 'QWJjZA==', 'Encoding "Abcd"';
    is encode-base64("Perl"), 'UGVybA==', 'Encoding "Perl"';
    is encode-base64("Perl6"), 'UGVybDY=', 'Encoding "Perl6"';
    is encode-base64("Another test!"), 'QW5vdGhlciB0ZXN0IQ==', 'Encoding "Another test!"';
    is encode-base64("username:thisisnotmypassword"), 'dXNlcm5hbWU6dGhpc2lzbm90bXlwYXNzd29yZA==', 'Encoding "username:thisisnotmypassword"';
    is encode-base64(Buf.new(0)), 'AA==', 'encode Test on NULL/0 byte';
    is encode-base64(Buf.new(1)), 'AQ==', 'encode Test on byte value 1';
    is encode-base64(Buf.new(255)), '/w==', 'encode Test on byte value 255';
}, 'Encode';

subtest {
    is decode-base64("").decode, '', 'decoding the empty string';
    is decode-base64("QQ==").decode, 'A', 'decoding "A"';
    is decode-base64("QWI=").decode, 'Ab', 'decoding "Ab"';
    is decode-base64('QWJj').decode, "Abc", 'decoding "Abc"';
    is decode-base64('QWJjZA==').decode, "Abcd", 'decoding "Abcd"';
    is decode-base64('UGVybA==').decode, "Perl", 'decoding "Perl"';
    is decode-base64('UGVybDY=').decode, "Perl6", 'decoding "Perl6"';
    is decode-base64("UGVy\nbDY=").decode, "Perl6", 'decoding "Perl6 with invalid b64 character"';
    is decode-base64('QW5vdGhlciB0ZXN0IQ==').decode, "Another test!", 'decoding "Another test!"';
    is decode-base64('dXNlcm5hbWU6dGhpc2lzbm90bXlwYXNzd29yZA==').decode, "username:thisisnotmypassword", 'decoding "username:thisisnotmypassword"';
    is-deeply decode-base64('AA=='), Buf.new(0), 'decode Test on NULL/0 byte';
    is-deeply decode-base64('AQ=='), Buf.new(1), 'decode Test on byte value 1';
    is-deeply decode-base64('/w=='), Buf.new(255), 'decode Test on byte value 255';
}, 'Decode';

subtest {
    is encode-base64("\x14\xfb\x9c\x03\xd9\x7e"), "FPucA9l+";
    is encode-base64("\x14\xfb\x9c\x03\xd9"),     "FPucA9k=";
    is encode-base64("\x14\xfb\x9c\x03"),         "FPucAw==";
}, 'RFC 3548';

subtest {
    my %from-to = :f<Zg==>, :fo<Zm8=>, :foo<Zm9v>, :foob<Zm9vYg==>, :fooba<Zm9vYmE=>, :foobar<Zm9vYmFy>;
    %from-to.pairs.map: {is encode-base64($_.key), $_.value; }
}, 'RFC 4648';

subtest {
    my @invalid = <!!!! ==== =AAA A=AA AA=A AA==A AAA=AAAA AAAAA AAAAAA A= A== AA= AA== AAA= AAAA AAAAAA=>;
    @invalid.map: { is-deeply decode-base64($_, :uri), Buf.new(0) }
}, 'Currupt/invalid encodings';