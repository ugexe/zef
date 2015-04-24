use Zef::Utils;
use Test;

plan 12;

is Zef::Utils.b64decode("").decode, '', 'decoding the empty string';
is Zef::Utils.b64decode("QQ==").decode, 'A', 'decoding "A"';
is Zef::Utils.b64decode("QWI=").decode, 'Ab', 'decoding "Ab"';
is Zef::Utils.b64decode('QWJj').decode, "Abc", 'decoding "Abc"';
is Zef::Utils.b64decode('QWJjZA==').decode, "Abcd", 'decoding "Abcd"';
is Zef::Utils.b64decode('UGVybA==').decode, "Perl", 'decoding "Perl"';
is Zef::Utils.b64decode('UGVybDY=').decode, "Perl6", 'decoding "Perl6"';
is Zef::Utils.b64decode('QW5vdGhlciB0ZXN0IQ==').decode, "Another test!", 'decoding "Another test!"';
is Zef::Utils.b64decode('dXNlcm5hbWU6dGhpc2lzbm90bXlwYXNzd29yZA==').decode, "username:thisisnotmypassword", 'decoding "username:thisisnotmypassword"';
is Zef::Utils.b64decode('AA=='), Buf.new(0), 'decode Test on NULL/0 byte';
is Zef::Utils.b64decode('AQ=='), Buf.new(1), 'decode Test on byte value 1';
is Zef::Utils.b64decode('/w=='), Buf.new(255), 'decode Test on byte value 255';
